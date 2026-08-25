#!/usr/bin/env bash
# 校验本地站点：所有页面可访问 + 中文编码正确 + 内部链接无断链
set -uo pipefail
PORT="${1:-8081}"
BASE="http://localhost:${PORT}"
fail=0

echo "══ 服务健康 ══"
if ! curl -fsS "${BASE}/healthz" >/dev/null 2>&1; then
  echo "  ✗ 服务未响应（${BASE}）。先运行：make up"
  exit 1
fi
echo "  ✓ ${BASE}/healthz"

echo
echo "══ 页面可访问性 ══"
for p in index methodology m1-foundations m2-ontology m3-agentic m4-adoption \
         m5-synthesis dia playbook domains research about; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "${BASE}/${p}.html")
  if [ "$code" = "200" ]; then printf "  ✓ %-20s %s\n" "$p" "$code"
  else printf "  ✗ %-20s %s\n" "$p" "$code"; fail=1; fi
done

echo
echo "══ 编码与内容类型 ══"
ct=$(curl -sI "${BASE}/index.html" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print $2}')
echo "  index.html → ${ct}"
[[ "$ct" == *"utf-8"* ]] || { echo "  ✗ 缺少 charset=utf-8"; fail=1; }
mdct=$(curl -sI "${BASE}/content/40-参考/04-引用与数据来源.md" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print $2}')
echo "  Markdown   → ${mdct}"
[[ "$mdct" == *"text/plain"* ]] || { echo "  ✗ Markdown 未以纯文本提供（会触发下载）"; fail=1; }

echo
echo "══ 内容库与文档可浏览 ══"
for u in "/content/" "/docs/" "/README.md"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "${BASE}${u}")
  if [ "$code" = "200" ]; then printf "  ✓ %-14s %s\n" "$u" "$code"
  else printf "  ✗ %-14s %s\n" "$u" "$code"; fail=1; fi
done

echo
echo "══ 站内链接与锚点 ══"
python3 - "$PORT" <<'PY'
import re,sys,urllib.request,urllib.parse
port=sys.argv[1]; base=f"http://localhost:{port}"
pages=["index","methodology","m1-foundations","m2-ontology","m3-agentic","m4-adoption",
       "m5-synthesis","dia","playbook","domains","research","about"]
html={}
for p in pages:
    try: html[p+".html"]=urllib.request.urlopen(f"{base}/{p}.html").read().decode("utf-8")
    except Exception as e: print(f"  ✗ 取不到 {p}.html: {e}")
ids={f:set(re.findall(r'id="([^"]+)"',s)) for f,s in html.items()}
bad=[]
for f,s in html.items():
    for href in re.findall(r'href="([^"]+)"',s):
        if href.startswith(("http","mailto:")): continue
        page,_,frag=href.partition("#"); page=page or f
        if page.endswith(".css"):
            try: urllib.request.urlopen(f"{base}/{page}")
            except Exception: bad.append((f,href,"css 404"))
            continue
        if page not in html: bad.append((f,href,"页面不存在"))
        elif frag and frag not in ids.get(page,set()): bad.append((f,href,"锚点不存在"))
print(f"  检查 {len(html)} 页")
if bad:
    print(f"  ✗ 断链 {len(bad)} 条")
    for b in bad: print("    ",b)
    sys.exit(1)
print("  ✓ 断链 0 条")
PY
[ $? -ne 0 ] && fail=1

echo
if [ $fail -eq 0 ]; then echo "全部通过 → ${BASE}"; else echo "有失败项，见上"; exit 1; fi
