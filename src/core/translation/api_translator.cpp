#include "core/translation/api_translator.h"
#include <stdexcept>
#include "core/translation/context.h"

// https://github.com/UlionTse/translators

namespace trnist::core::translation
{
    constexpr std::string_view MODULE_NAME{ "translators" };

    ApiTranslator::ApiTranslator()
    : python_guard_(MODULE_NAME.data())
    {}

    std::u16string ApiTranslator::translate(const std::u16string& text, const Context& context) const
    {
        try {
            auto translators = py::module_::import(MODULE_NAME.data());
            py::object result = translators.attr("translate_text")(text, context.api, context.from_lang, context.to_lang);
            return result.cast<std::u16string>();
        } catch (const py::error_already_set& e) {
            throw std::runtime_error("Translation failed: " + std::string(e.what()));
        }
    }
}