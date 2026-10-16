"""홈페이지 공유용 빌드 (claude.ai Artifact 등 제한된 미리보기 환경용).

index.html 에서 문서 래퍼 태그를 빼고, 앱 버튼은 시연 앱 링크로, 컨퍼런스 링크는 GitHub Pages 주소로 바꿉니다.
assets/site.css, assets/site.js 와 이미지는 Artifact 의 files 로 함께 올립니다.
사용: python3 tools/build_site_artifact.py <출력 경로> <앱 링크>
"""
import re, sys
SITE = 'https://koreayjk.github.io/svm/'
out = open('index.html', encoding='utf-8').read()
for pat in [r'<!doctype html>\s*', r'<html[^>]*>\s*', r'</html>\s*', r'<head>\s*', r'</head>\s*', r'<body>\s*', r'</body>\s*',
            r'<meta charset="utf-8">\s*', r'<meta name="viewport"[^>]*>\s*', r'<meta property="og:[^>]*>\s*', r'<meta name="theme-color"[^>]*>\s*']:
    out = re.sub(pat, '', out, flags=re.I)
out = out.replace('href="conference/', f'href="{SITE}conference/')
out = out.replace("window.SVM_BASE = '';", f"window.SVM_BASE = ''; window.SVM_APP_URL = '{sys.argv[2]}';")
out = out.replace('</title>', '</title>\n<meta name="claude:viewport-fit-sides" content="cover">', 1)
assert out.lstrip().startswith('<title>')
open(sys.argv[1], 'w', encoding='utf-8').write(out)
print('wrote', sys.argv[1], len(out), 'bytes')
