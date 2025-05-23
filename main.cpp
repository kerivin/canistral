#include <QApplication>
#include <QMainWindow>
#include <QMessageBox>
#include <sqlite3.h>
#include "core/translation/api_translator.h"
#include "core/translation/context.h"
#include <filesystem>

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
			fs::path py_modules_path = exe_dir / "python_modules";
			py::module_::import("sys").attr("path").attr("append")(py_modules_path.string());

			QMessageBox::information(nullptr, "Python version", QString::fromStdString(sys.attr("version").cast<std::string>()));

			trnist::py::module_ site = trnist::py::module_::import("site");
			const auto site_list = site.attr("getsitepackages")().cast<trnist::py::list>();
			QString qsite;
			for (const auto &site : site_list)
				qsite.append(QString::fromStdString(site.cast<std::string>()) + "\n");
			QMessageBox::information(nullptr, "Python site-packages", qsite);

			const auto path_list = sys.attr("path").cast<trnist::py::list>();
			QString qpath;
			for (const auto &path : path_list)
				qpath.append(QString::fromStdString(path.cast<std::string>()) + "\n");
			QMessageBox::information(nullptr, "Python path", qpath);
		}
		catch (const std::exception &e)
		{
			QMessageBox::critical(nullptr, "Error", e.what());
		}

		QMainWindow mainWindow;
		mainWindow.setWindowTitle("tr-nist");
		mainWindow.resize(800, 600);
		mainWindow.show();

		sqlite3 *db;
		if (sqlite3_open(":memory:", &db) == SQLITE_OK)
		{
			sqlite3_close(db);
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

		// finalize_embedded_python();
		return app.exec();
	}
}