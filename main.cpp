#include <filesystem>
#include <QApplication>
#include <QMainWindow>
#include <QMessageBox>
#include "core/translation/api_translator.h"
#include "core/translation/context.h"
#include "pybind.h"

// PyStatus initialize_embedded_python();
// void finalize_embedded_python();

namespace fs = std::filesystem;
using namespace trnist;

int main(int argc, char *argv[])
{
	QApplication app(argc, argv);

	// if (const auto python_status = initialize_embedded_python(); python_status.err_msg)
	// {
	//     std::string python_error(python_status.err_msg);
	//     QMessageBox::information(nullptr, "Python status", QString::fromStdString(python_error));
	//     return python_status.exitcode;
	// }
	// else
	{
		trnist::py::scoped_interpreter guard{};

		try
		{
			py::module_ sys = py::module_::import("sys");
			fs::path exe_dir = fs::path(argv[0]).parent_path();
			sys.attr("path").attr("append")(fs::path(exe_dir / "py_modules").string());

			try {
				py::module_ qt_exejs = py::module_::import("qt_exejs");
			} catch (py::error_already_set &e) {
				QMessageBox::critical(nullptr, "Error", e.what());
			}

			py::exec(R"(
				import sys
				import qt_exejs
				sys.modules['exejs'] = qt_exejs
				exejs = qt_exejs
			)");
		}
		catch (const std::exception &e)
		{
			QMessageBox::critical(nullptr, "Error", e.what());
		}

		QMainWindow mainWindow;
		mainWindow.resize(800, 600);
		mainWindow.show();

		try
		{
			trnist::core::translation::ApiTranslator translator;
			QString result = QString::fromStdU16String(translator.translate(u"Alas, poor country! Almost afraid to know itself!",
																			{.api = "yandex", .from_lang = "en", .to_lang = "ru"}));
			QMessageBox::information(nullptr, "Translation", result);
		}
		catch (const std::exception &e)
		{
			QMessageBox::critical(nullptr, "Error", e.what());
		}

		// finalize_embedded_python();
		return app.exec();
	}
}