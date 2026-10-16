"""랜딩페이지 공유용 빌드 (claude.ai Artifact 등 제한된 미리보기 환경용).

landing.html 에서 문서 래퍼 태그를 빼고, 가입 버튼을 시연 앱 링크로 바꿉니다.
사용: python3 tools/build_landing_artifact.py <출력 경로> <앱 링크>
"""
import re, sys
out = open('landing.html', encoding='utf-8').read()
for pat in [r'<!doctype html>\s*', r'<html[^>]*>\s*', r'</html>\s*', r'<head>\s*', r'</head>\s*', r'<body>\s*', r'</body>\s*',
            r'<meta charset="utf-8">\s*', r'<meta name="viewport"[^>]*>\s*', r'<meta property="og:[^>]*>\s*']:
    out = re.sub(pat, '', out, flags=re.I)
out = out.replace("const APP_URL = 'index.html';", f"const APP_URL = '{sys.argv[2]}';")
out = out.replace('</title>', '</title>\n<meta name="claude:viewport-fit-sides" content="cover">', 1)
assert out.lstrip().startswith('<title>')
open(sys.argv[1], 'w', encoding='utf-8').write(out)
print('wrote', sys.argv[1], len(out), 'bytes')
