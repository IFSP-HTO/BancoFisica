#!/usr/bin/env python3
"""Testes locais, sem rede, das regras editoriais de importação."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import importar_questoes as imp


def fixture(approved=False):
    item = {
        "id": "teste-2025-q11",
        "url": "https://provas.professorfilatte.com.br/teste-2025-fisica-questao-11",
        "correct": "C",
        "pedagogy": {
            "topic": "empuxo", "skill": "calcular peso aparente",
            "difficulty": "media", "decision": "aprovada" if approved else "candidata",
            "justification": "conceito pouco representado",
            "reason_for_selection": "resolução diferente das existentes",
            "quality": {"clareza": 5, "correcao_fisica": 5,
                        "alinhamento_curricular": 5, "raciocinio": 4}
        },
        "verification": {k: True for k in imp.APPROVAL_CHECKS} if approved else {}
    }
    return {"schema_version": 1, "source": "professor-filatte",
            "subject": "hidrostatica", "batch_id": "lote-teste-001",
            "questions": [item]}


class TestImportacao(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "BancoDeQuestoes").mkdir()

    def check(self, data):
        path = self.root / "lote.json"
        path.write_text(json.dumps(data), encoding="utf-8")
        return imp.inspect_manifest(path, self.root)

    def test_candidata_com_ficha_valida(self):
        _, problems, _ = self.check(fixture())
        self.assertEqual(problems, [])

    def test_aprovada_exige_verificacoes_e_rubrica(self):
        data = fixture(approved=True)
        _, problems, _ = self.check(data)
        self.assertEqual(problems, [])
        data["questions"][0]["verification"]["fisica_conferida"] = False
        _, problems, _ = self.check(data)
        self.assertTrue(any("fisica_conferida" in p for p in problems))
        data["questions"][0]["verification"]["fisica_conferida"] = True
        data["questions"][0]["pedagogy"]["quality"]["correcao_fisica"] = 4
        _, problems, _ = self.check(data)
        self.assertTrue(any("física deve receber 5" in p for p in problems))

    def test_selecao_exige_checagem_de_fonte(self):
        data = fixture()
        data["questions"][0]["pedagogy"]["decision"] = "selecionada"
        _, problems, _ = self.check(data)
        self.assertTrue(any("enunciado e gabarito" in p for p in problems))

    def test_duplicata_por_id_url_e_banco(self):
        data = fixture()
        data["questions"].append(dict(data["questions"][0]))
        _, problems, _ = self.check(data)
        self.assertTrue(any("ID duplicado" in p for p in problems))
        self.assertTrue(any("URL duplicada" in p for p in problems))
        data = fixture()
        (self.root / "BancoDeQuestoes" / "questao.Rnw").write_text(
            "%% SOURCE-URL: " + data["questions"][0]["url"], encoding="utf-8")
        _, problems, _ = self.check(data)
        self.assertTrue(any("URL já encontrada" in p for p in problems))

    def test_injecao_de_url_ou_identificador_bloqueada(self):
        data = fixture()
        data["questions"][0]["id"] = "../fora"
        _, problems, _ = self.check(data)
        self.assertTrue(any("id inválido" in p for p in problems))
        data = fixture()
        data["questions"][0]["url"] = "https://other.example/questao"
        _, problems, _ = self.check(data)
        self.assertTrue(any("URL fora" in p for p in problems))

    def test_lote_vazio_nao_simula_importacao(self):
        data = fixture()
        data["questions"] = []
        _, problems, alerts = self.check(data)
        self.assertEqual(problems, [])
        self.assertTrue(any("sem itens" in x for x in alerts))

    def test_recorte_exige_hash_e_revisao_visual(self):
        stage = self.root / "stage"
        stage.mkdir()
        sha = "a" * 64
        (stage / "manifest.json").write_text(json.dumps({
            "items": [{"id": "teste-2025-q11", "status": "pending_visual_review",
                       "sha256": sha}]
        }), encoding="utf-8")
        plan = {"items": [{"id": "teste-2025-q11", "source_sha256": sha,
                           "visual_reviewed": True,
                           "figures": [{"name": "imagem.png", "box": [0, 0, 100, 80]}]}]}
        path = self.root / "figuras.json"
        path.write_text(json.dumps(plan), encoding="utf-8")
        self.assertEqual(imp.check_crop_plan(path, stage), (1, 1))
        plan["items"][0]["visual_reviewed"] = False
        path.write_text(json.dumps(plan), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "conferência visual"):
            imp.check_crop_plan(path, stage)
        plan["items"][0]["visual_reviewed"] = True
        plan["items"][0]["figures"][0]["name"] = "../imagem.png"
        path.write_text(json.dumps(plan), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Nome inseguro"):
            imp.check_crop_plan(path, stage)


if __name__ == "__main__":
    unittest.main()
