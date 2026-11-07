import sys
sys.path.insert(0, '.')
out = []
try:
    import test_calc as t
    for name in ('test_add', 'test_average'):
        try:
            getattr(t, name)(); out.append(name + ' pass')
        except Exception as e:
            out.append(name + ' FAIL')
except Exception as e:
    out.append('import error ' + type(e).__name__)
print('; '.join(out))
