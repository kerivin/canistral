#include <QApplication>
#include <QMainWindow>
#include <QMessageBox>
#include <sqlite3.h>
#include "core/translation/api_translator.h"
#include "core/translation/context.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QMainWindow mainWindow;
    mainWindow.setWindowTitle("TRnist");
    mainWindow.resize(800, 600);
    mainWindow.show();

    sqlite3 *db;
    if (sqlite3_open(":memory:", &db) == SQLITE_OK)
    {
        sqlite3_close(db);
    }

    {
        trnist::py::scoped_interpreter guard{};
        auto sys = trnist::py::module_::import("sys");
        QMessageBox::information(nullptr, "Python version", QString::fromStdString(sys.attr("version").cast<std::string>()));
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

    return app.exec();
}