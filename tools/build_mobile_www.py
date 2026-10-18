"""구글플레이·앱스토어 앱(Capacitor)에 넣을 웹 파일 만들기.

app/index.html 을 mobile/www/index.html 로 복사하면서
  · Supabase 라이브러리를 CDN 대신 앱 안에 포함 (첫 실행·약한 네트워크에서도 바로 뜨게)
  · ../config.js, ../assets/, ../icons/ 경로를 www 안으로
  · 개인정보·이용약관·컨퍼런스 링크는 웹사이트 주소로
  · 웹앱 전용(매니페스트·서비스 워커)은 빼기
사용: python3 tools/build_mobile_www.py   (mobile 폴더에서 npm run web 과 같음)
"""
import os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WWW = os.path.join(ROOT, 'mobile', 'www')
SITE = 'https://koreayjk.github.io/svm/'
SUPABASE_UMD = os.path.join(ROOT, 'mobile', 'node_modules', '@supabase', 'supabase-js', 'dist', 'umd', 'supabase.js')

html = open(os.path.join(ROOT, 'app', 'index.html'), encoding='utf-8').read()
html = re.sub(r'<script src="https://cdn\.jsdelivr\.net/npm/@supabase/supabase-js@[^"]+"></script>', '<script src="vendor/supabase.js"></script>', html)
html = re.sub(r'<link rel="manifest"[^>]*>\s*', '', html)
html = html.replace('"../config.js"', '"config.js"')
for page in ('privacy', 'terms', 'conference'):
    html = html.replace(f"'../{page}/", f"'{SITE}{page}/")
html = html.replace('../assets/', 'assets/').replace('../icons/', 'icons/')
assert '../' not in re.sub(r'https?://\S+', '', html), 'relative ../ path left'
assert 'vendor/supabase.js' in html, 'supabase script tag not replaced'

if os.path.isdir(WWW):
    shutil.rmtree(WWW)
os.makedirs(os.path.join(WWW, 'vendor'))
open(os.path.join(WWW, 'index.html'), 'w', encoding='utf-8').write(html)
if not os.path.exists(SUPABASE_UMD):
    sys.exit('Run "npm install" in the mobile folder first (Supabase library missing).')
shutil.copy(SUPABASE_UMD, os.path.join(WWW, 'vendor', 'supabase.js'))
shutil.copy(os.path.join(ROOT, 'config.js'), os.path.join(WWW, 'config.js'))
shutil.copytree(os.path.join(ROOT, 'icons'), os.path.join(WWW, 'icons'))
os.makedirs(os.path.join(WWW, 'assets'))
for f in ('SVM_Logo.svg', 'SVM_Logo_white.svg', 'world-dots.svg', 'worldmap.js'):
    shutil.copy(os.path.join(ROOT, 'assets', f), os.path.join(WWW, 'assets', f))
shutil.copytree(os.path.join(ROOT, 'assets', 'countries'), os.path.join(WWW, 'assets', 'countries'))
print('wrote', WWW)
