#pragma once
#include <string_view>

namespace trnist::core::translation
{
	struct Context
	{
		std::string_view api;
		std::string_view from_lang{"auto"};
		std::string_view to_lang{"en"};
	};
}