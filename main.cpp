#include <QApplication>
#include <QMainWindow>
#include <QMessageBox>
#include <sqlite3.h>
#include "core/translation/api_translator.h"
#include "core/translation/context.h"

// PyStatus initialize_embedded_python();
// void finalize_embedded_python();

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
            trnist::py::scoped_interpreter guard{};
            auto sys = trnist::py::module_::import("sys");
            QMessageBox::information(nullptr, "Python version", QString::fromStdString(sys.attr("version").cast<std::string>()));

            trnist::py::module_ site = trnist::py::module_::import("site");
            const auto site_list = site.attr("getsitepackages")().cast<trnist::py::list>();
            QString qsite;
            for (const auto& site : site_list)
                qsite.append(QString::fromStdString(site.cast<std::string>()) + "\n");
            QMessageBox::information(nullptr, "Python site-packages", qsite);

            const auto path_list = sys.attr("path").cast<trnist::py::list>();
            QString qpath;
            for (const auto& path : path_list)
                qpath.append(QString::fromStdString(path.cast<std::string>()) + "\n");
            QMessageBox::information(nullptr, "Python path", qpath);
        }
        catch (const std::exception &e)
        {
            QMessageBox::critical(nullptr, "Error", e.what());
        }

        try
        {
            trnist::core::translation::ApiTranslator translator;
            QString result = QString::fromStdU16String(translator.translate(u"Alas, poor country! Almost afraid to know itself!",
                { .api = "yandex", .from_lang = "en", .to_lang = "ru"}));
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