import json
import re

class QtRuntime:
    def __init__(self):
        self.engine = self._get_js_engine()
        self.name = "QtJSEngine"
        self.command = ["qtjs"]  # Dummy value for compatibility
        self.run_source = ""     # Not used in Qt implementation
        
    def is_available(self):
        return True
        
    def compile(self, source='', cwd=None):
        return QtCompileContext(self, source, cwd)
    
    def _get_js_engine(self):
        from PyQt6.QtQml import QJSEngine
        return QJSEngine()

class QtCompileContext:
    def __init__(self, runtime, source='', cwd=None):
        self.runtime = runtime
        self.source = source
        self.cwd = cwd  # Not used but kept for compatibility
        
    def encode_unicode_codepoints(self, text):
        """Maintain compatibility with original encoding"""
        return re.sub(pattern='[^\x00-\x7f]', 
                     repl=lambda x: '\\u{0:04x}'.format(ord(x.group(0))), 
                     string=text)

    def execute(self, source):
        full_source = f'{self.source}\n{source}' if self.source else source
        return self._evaluate(full_source)
        
    def evaluate(self, source):
        if source.strip():
            wrapped_source = f"return eval('(' + {json.dumps(source)} + ')')"
        else:
            wrapped_source = "return ''"
        return self._evaluate(wrapped_source)
        
    def call(self, key, *args):
        args_json = json.dumps(args)
        return self.evaluate(f'{key}.apply(this, {args_json})')
        
    def _evaluate(self, source):
        try:
            result = self.runtime.engine.evaluate(source)
            if result.isError():
                error_msg = result.toString()
                if "ReferenceError" in error_msg:
                    raise NameError(error_msg)
                elif "SyntaxError" in error_msg:
                    raise SyntaxError(error_msg)
                else:
                    raise RuntimeError(error_msg)
            return result.toVariant()
        except Exception as e:
            raise RuntimeError(f"QtJSEngine error: {str(e)}")

qt_runtime = QtRuntime()

class Tse:
    def __init__(self):
        self.current_runtime = qt_runtime
    
    def compile(self, source='', cwd=None):
        return self.current_runtime.compile(source, cwd)
    
    def execute(self, source):
        return self.compile().execute(source)
    
    def evaluate(self, source):
        return self.compile().evaluate(source)

tse = Tse()
compile = tse.compile
execute = tse.execute
evaluate = tse.evaluate
runtime = tse.current_runtime

class ExejsRuntimeUnavailableError(Exception): pass
class ExejsProcessExitError(Exception): pass
class ExejsProgramError(Exception): pass