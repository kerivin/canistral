#pragma once
#include <pybind11/embed.h>
#include <string_view>

namespace trnist
{
	namespace py = pybind11;

	struct PythonGuard final
	{
		PythonGuard(std::string_view module_name)
		{
			if (!Py_IsInitialized())
			{
				py::initialize_interpreter();
				py::module_::import(module_name.data());
			}
		}
		~PythonGuard()
		{
			if (Py_IsInitialized())
			{
				py::finalize_interpreter();
			}
		}
	};
}

#define PYTHON_WRAPPER __attribute__((visibility("default")))