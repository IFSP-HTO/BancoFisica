"""Black-box regression tests for the ChatGPT -> Git blob image preflight."""
import base64
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "tools" / "verify_image_blob.py"
PNG_B64 = "iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAIAAAASFvFNAAAAFUlEQVR42mP4z8DAAMH/gdR/IPEfAErJCPhfs311AAAAAElFTkSuQmCC"
PNG_DATA = base64.b64decode(PNG_B64)
EXPECTED_SHA = "5c3200439d2b67487758bb559325812fbcd0909e"


class ImageBlobVerifierTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.image = self.root / "image.png"
        self.image.write_bytes(PNG_DATA)

    def run_script(self, *extra):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(self.image), *map(str, extra)],
            capture_output=True, text=True, check=False,
        )

    def test_known_png_git_hash_and_dimensions(self):
        res = self.run_script("--remote-sha", EXPECTED_SHA)
        self.assertEqual(res.returncode, 0, res.stderr)
        data = json.loads(res.stdout)
        self.assertEqual(data["git_blob_sha1"], EXPECTED_SHA)
        self.assertEqual(data["format"], "PNG")
        self.assertEqual((data["width"], data["height"]), (3, 2))
        self.assertTrue(data["remote_sha_matches"])
        self.assertEqual(data["sha256"], hashlib.sha256(PNG_DATA).hexdigest())

    def test_bad_remote_hash_stops(self):
        res = self.run_script("--remote-sha", "0" * 40)
        self.assertEqual(res.returncode, 2)
        self.assertFalse(json.loads(res.stdout)["remote_sha_matches"])

    def test_base64_preserves_exact_original_bytes(self):
        output = self.root / "transfer.b64"
        res = self.run_script("--base64-out", output)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(base64.b64decode(output.read_text()), PNG_DATA)

    def test_rejects_missing_iend(self):
        self.image.write_bytes(PNG_DATA[:-12])
        res = self.run_script()
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("IEND", res.stderr)

    def test_rejects_nonimage_input(self):
        self.image.write_text("This is not a PNG")
        res = self.run_script()
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Formato nao suportado", res.stderr)

    def test_rejects_missing_file(self):
        self.image.unlink()
        res = self.run_script()
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("Arquivo nao encontrado", res.stderr)


if __name__ == "__main__":
    unittest.main()
