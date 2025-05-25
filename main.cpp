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
			py::module_::import("sys").attr("path").attr("append")(fs::path(exe_dir / "py_modules").string());

			py::exec(R"(
				import exejs
				import qt_exejs

				exejs.runtime = qt_exejs.runtime
				exejs.compile = qt_exejs.compile
				exejs.execute = qt_exejs.execute
				exejs.evaluate = qt_exejs.evaluate
				exejs.Tse = qt_exejs.Tse
				exejs.tse = qt_exejs.tse
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