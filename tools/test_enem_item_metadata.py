import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("enem_item_metadata.py")
spec = importlib.util.spec_from_file_location("enem_item_metadata", MODULE_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)


class EnemMetadataTests(unittest.TestCase):
    def test_match_by_position_and_color(self):
        inv = {field: "" for field in mod.OUTPUT_FIELDS}
        inv.update(
            {
                "bank_path": "BancoDeQuestoes/x/Q.Rnw",
                "relation": "direct",
                "source_year": "2024",
                "source_position": "100",
                "source_color": "Cinza",
            }
        )
        items = [
            {
                "CO_ITEM": "11",
                "CO_PROVA": "1",
                "CO_POSICAO": "100",
                "TX_COR": "CINZA",
                "SG_AREA": "CN",
                "CO_HABILIDADE": "7",
                "NU_PARAM_A": "1,2",
                "NU_PARAM_B": "0,3",
                "NU_PARAM_C": "0,20",
            },
            {
                "CO_ITEM": "22",
                "CO_PROVA": "2",
                "CO_POSICAO": "100",
                "TX_COR": "AZUL",
                "SG_AREA": "CN",
            },
        ]
        found = mod.candidates(inv, items)
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]["CO_ITEM"], "11")

    def test_pre_tri_is_not_matched(self):
        inv = {field: "" for field in mod.OUTPUT_FIELDS}
        inv.update({"bank_path": "x", "relation": "direct", "source_year": "2001"})
        out, messages = mod.match_inventory([inv], {})
        self.assertEqual(out[0]["match_status"], "pre_tri")
        self.assertEqual(messages, [])

    def test_reads_item_csv_inside_zip(self):
        with tempfile.TemporaryDirectory() as td:
            zpath = Path(td) / "microdados_enem_2024.zip"
            data = (
                "CO_ITEM;CO_PROVA;CO_POSICAO;TX_COR;SG_AREA\n"
                "1;2;100;CINZA;CN\n"
            ).encode("latin-1")
            with zipfile.ZipFile(zpath, "w") as zf:
                zf.writestr("DADOS/ITENS_PROVA_2024.csv", data)
            rows = mod.load_inep_items(zpath, 2024)
            self.assertEqual(rows[0]["CO_ITEM"], "1")


if __name__ == "__main__":
    unittest.main()
