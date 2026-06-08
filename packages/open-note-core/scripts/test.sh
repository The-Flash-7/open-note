#!/bin/bash
set -e

echo "====================================="
echo "  测试 open-note-core"
echo "====================================="

cd "$(dirname "$0")/.."

# 安装依赖
echo "[信息] 安装 open-note-core..."
pip install -e . > /dev/null 2>&1

# 运行测试
echo "[信息] 运行测试..."
python3 -c "
import tempfile, os
from open_note_core.storage.note_storage import NoteStorage
from open_note_core.models.note import Note

# 使用临时数据库进行测试
db_path = os.path.join(tempfile.gettempdir(), 'opennote_test.db')
storage = NoteStorage(db_path)

# 测试创建笔记
print('- 测试创建笔记...')
note = storage.create_note('测试笔记', '这是测试内容', category='测试', tags=['测试', '自动化'])
assert note, '创建笔记失败'
note_id = note['id']
print(f'  ✅ 笔记已创建: {note_id[:8]}')

# 测试查询笔记
print('- 测试查询笔记...')
found = storage.get_note(note_id)
assert found, '查询笔记失败'
assert found['title'] == '测试笔记', '标题不匹配'
print(f'  ✅ 查询成功: {found[\"title\"]}')

# 测试搜索笔记
print('- 测试搜索笔记...')
results = storage.search_notes('测试内容')
assert len(results) > 0, '搜索笔记失败'
print(f'  ✅ 搜索到 {len(results)} 条结果')

# 测试列表笔记
print('- 测试获取笔记列表...')
notes = storage.get_notes(limit=10)
assert len(notes) > 0, '获取列表失败'
print(f'  ✅ 列表包含 {len(notes)} 条笔记')

# 测试删除笔记
print('- 测试删除笔记...')
success = storage.delete_note(note_id)
assert success, '删除笔记失败'
deleted = storage.get_note(note_id)
assert deleted is None, '笔记未被删除'
print(f'  ✅ 删除成功')

# 清理测试数据
os.remove(db_path)
print('')
print('=====================================')
print('  ✅ open-note-core 测试通过!')
print('=====================================')
"
