#include <QCoreApplication>
#include <QMainWindow>
#include <sqlite3.h>

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    QMainWindow window;
    window.setWindowTitle("Canistral");

    sqlite3 *db;
    sqlite3_open(":memory:", &db);
    sqlite3_close(db);

    window.show();
    return 0;
}