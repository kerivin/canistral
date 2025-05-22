#pragma once
#include <string>

namespace trnist::core::translation
{
	class Context;

	class ITranslator
	{
	public:
		virtual ~ITranslator() = default;
		virtual std::u16string translate(const std::u16string&, const Context&) const = 0;
	};
}