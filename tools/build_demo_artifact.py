"""데모 시연용 단일 페이지 빌드 (claude.ai Artifact 등 제한된 미리보기 환경용).

app/index.html 에서 문서 래퍼 태그·Supabase 라이브러리·config.js 를 빼고, 파일 저장·공유 버튼을 끕니다.
경로는 저장소 루트 기준(assets/, icons/)으로 바꿉니다.
사용: python3 tools/build_demo_artifact.py <출력 경로>
"""
import re, sys
SITE = 'https://koreayjk.github.io/svm/'
out = open('app/index.html', encoding='utf-8').read()
for pat in [r'<!doctype html>\s*', r'<html[^>]*>\s*', r'</html>\s*', r'<head>\s*', r'</head>\s*', r'<body>\s*', r'</body>\s*',
            r'<meta charset="utf-8">\s*', r'<meta name="viewport"[^>]*>\s*', r'<link rel="manifest"[^>]*>\s*',
            r'<link rel="apple-touch-icon"[^>]*>\s*', r'<meta name="apple-[^>]*>\s*', r'<meta property="og:[^>]*>\s*',
            r'<script src="https://cdn.jsdelivr.net/npm/@supabase[^>]*></script>\s*', r'<script src="\.\./config\.js"></script>\s*']:
    out = re.sub(pat, '', out, flags=re.I)
out = out.replace("'../conference/", f"'{SITE}conference/").replace("'../privacy/", f"'{SITE}privacy/").replace("'../terms/", f"'{SITE}terms/").replace("'../host/", f"'{SITE}host/")
out = out.replace('../assets/', 'assets/').replace('../icons/', 'icons/')
out = re.sub(r'<title>.*?</title>', '<title>SVM Mission App</title>', out, count=1)
out = out.replace("const CAN_DOWNLOAD = !NATIVE;", "const CAN_DOWNLOAD = false;")
out = out.replace("if (!NATIVE && 'serviceWorker' in navigator && location.protocol !== 'file:')", "if (false)")
# 데모 전용: 연결 정보가 있어도 데모로
out = out.replace("const DEMO = !configured || FORCE_DEMO;", "const DEMO = true;")
out = out.replace("if (!configured && !DEMO)", "if (false)")
for must in ['const DEMO = true;', 'const CAN_DOWNLOAD = false;', 'if (false)']:
    assert must in out, must
assert '../' not in re.sub(r'https?://\S+', '', out), 'relative ../ path left'
assert out.lstrip().startswith('<title>'), out[:80]
open(sys.argv[1], 'w', encoding='utf-8').write(out)
print('wrote', sys.argv[1], len(out), 'bytes')
