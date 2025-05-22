#include "python_guard.h"

namespace trnist
{
	struct __attribute__((visibility("default"))) PythonGuard::PythonRuntime
	{
		py::scoped_interpreter interpreter;
	};

	PythonGuard::PythonGuard()
		: py_runtime_(std::make_unique<PythonRuntime>())
	{
	}

	PythonGuard::~PythonGuard() = default;

	py::gil_scoped_acquire PythonGuard::acquire() const
	{
		return py::gil_scoped_acquire{};
	}
}