#pragma once
#include "python.h"
#include "i_translator.h"

namespace trnist::core::translation
{
	class ApiTranslator : public ITranslator
	{
	public:
		ApiTranslator();
		std::u16string translate(const std::u16string&, const Context&) const override;

	private:
		PythonGuard python_guard_;
	};
}