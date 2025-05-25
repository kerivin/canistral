#include <filesystem>
#include <QApplication>
#include <QMainWindow>
#include <QMessageBox>
#include <QQmlEngine>
#include "core/translation/api_translator.h"
#include "core/translation/context.h"
#include "pybind.h"

namespace fs = std::filesystem;
using namespace trnist;

int main(int argc, char *argv[])
{
	QApplication app(argc, argv);
	QMainWindow mainWindow;
	QQmlEngine engine;

	mainWindow.resize(800, 600);
	mainWindow.show();

	trnist::py::scoped_interpreter guard{};

	try
	{
		py::module_ sys = py::module_::import("sys");
		fs::path exe_dir = fs::path(argv[0]).parent_path();
		sys.attr("path").attr("append")(fs::path(exe_dir / "py_modules").string());
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

	return app.exec();
}