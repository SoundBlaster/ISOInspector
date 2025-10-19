import importlib.util
import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from tempfile import TemporaryDirectory

MODULE_PATH = Path(__file__).resolve().parents[1] / "validate_json.py"
spec = importlib.util.spec_from_file_location("scripts.validate_json", MODULE_PATH)
validate_json = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validate_json)


class ValidateIndentationTests(unittest.TestCase):
    def test_lines_starting_with_t_are_not_flagged(self) -> None:
        text = "[\n  true,\n  false\n]\n"

        buffer = io.StringIO()
        with redirect_stdout(buffer):
            result = validate_json._validate_indentation(Path("dummy.json"), text)

        self.assertTrue(result)
        self.assertEqual(buffer.getvalue(), "")

    def test_tabs_in_indentation_are_reported(self) -> None:
        text = "[\n\ttrue\n]\n"

        buffer = io.StringIO()
        with redirect_stdout(buffer):
            result = validate_json._validate_indentation(Path("dummy.json"), text)

        self.assertFalse(result)
        self.assertIn("indentation uses tabs", buffer.getvalue())


class ValidateColonSpacingTests(unittest.TestCase):
    def test_missing_space_after_colon_is_reported(self) -> None:
        text = '{"key":1}'

        buffer = io.StringIO()
        with redirect_stdout(buffer):
            result = validate_json._validate_colon_spacing(Path("dummy.json"), text)

        self.assertFalse(result)
        self.assertIn("expected a single space after ':'", buffer.getvalue())


class ValidateFileTests(unittest.TestCase):
    def test_boolean_array_file_passes_validation(self) -> None:
        text = "[\n  true,\n  false\n]\n"

        with TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "data.json"
            path.write_text(text, encoding="utf-8")

            buffer = io.StringIO()
            with redirect_stdout(buffer):
                result = validate_json.validate_file(path)

        self.assertTrue(result)
        self.assertEqual(buffer.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
