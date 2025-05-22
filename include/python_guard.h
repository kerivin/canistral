#pragma once
#include <memory>
#include "python.h"

namespace trnist
{
	class PythonGuard final
	{
	public:
		PythonGuard();
		~PythonGuard();
		[[nodiscard]] py::gil_scoped_acquire acquire() const;

	private:
		struct PythonRuntime;
		std::unique_ptr<PythonRuntime> py_runtime_;
	};
}