#!/bin/bash
# 检查 open-note-mcp 依赖许可证是否与 MIT + Apache 2.0 兼容

set -e

cd "$(dirname "$0")/.." || exit 1

# 从 pyproject.toml 提取依赖列表
DEPS=$(grep -A 20 'dependencies = \[' pyproject.toml | grep '"' | sed 's/.*"\([^"]*\)".*/\1/' | sed 's/[><=!].*//' | tr '[:upper:]' '[:lower:]')

echo "正在检查 open-note-mcp 依赖许可证..."
echo ""

pip-licenses --format=json 2>/dev/null | python3 -c "
import json, sys

# 读取 pyproject.toml 中的包名
deps = set()
for line in '''$DEPS'''.strip().split('\n'):
    name = line.strip().lower()
    if name and not name.startswith('open-note'):  # 跳过本地依赖
        deps.add(name)

ALLOWED_KEYWORDS = [
    'MIT',
    'BSD',
    'Apache',
    'ISC',
    'PSF',
    'HPND',
    'Zope',
    'MPL',
    'Zlib',
    'CC0',
    '0BSD',
]

data = json.load(sys.stdin)
violations = []
checked = 0

for pkg in data:
    name = pkg.get('Name', '')
    license = pkg.get('License', '')
    pkg_lower = name.lower()

    # 只检查 pyproject.toml 中的包
    if pkg_lower not in deps:
        continue

    checked += 1
    is_allowed = any(k.lower() in license.lower() for k in ALLOWED_KEYWORDS)

    if not is_allowed:
        violations.append({'name': name, 'license': license})

print(f'已检查 {checked} 个包')
print('')

if violations:
    print('⚠️  许可证冲突！以下依赖的许可证需要人工确认：')
    for v in violations:
        print(f'  - {v[\"name\"]}: {v[\"license\"]}')
    print('')
    print('提示：这些可能是别名或组合许可证，不一定真的不兼容')
    print('      请手动检查每个包的 LICENSE 文件')
    sys.exit(1)
else:
    print('✅ 所有依赖许可证均与 MIT + Apache 2.0 兼容')
"
