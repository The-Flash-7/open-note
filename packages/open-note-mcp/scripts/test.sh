#!/bin/bash
set -e

echo "====================================="
echo "  测试 open-note-mcp"
echo "====================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# 安装依赖
echo "[信息] 安装依赖包..."
cd ../open-note-core && pip install -e . > /dev/null 2>&1 && cd ..
cd open-note-mcp && pip install -e . > /dev/null 2>&1 && cd ..

# 使用临时数据库进行测试
export OPENNOTE_DB_PATH="$(mktemp /tmp/opennote_test_mcp_XXXXXX).db"

# 测试服务器能否正常启动（使用与 pip 相同的 Python）
PYTHON_BIN=$(which python3.11 || which python3)

echo "[信息] 测试 MCP 服务器..."
echo ""

# ==================== 基础初始化测试 ====================

$PYTHON_BIN -c "
import sys, os
sys.path.insert(0, 'open-note-mcp/src')
from open_note_mcp.mcp_server import server, storage
print('- 验证服务器初始化...')
assert server is not None, '服务器初始化失败'
assert storage is not None, '存储层初始化失败'
print('  ✅ 服务器初始化成功')
print('- 验证工具注册...')
tools = ['search_notes', 'list_notes', 'get_note', 'create_note', 'update_note', 'delete_note']
registered = [t.name for t in server._tool_manager.list_tools()]
for tool in tools:
    assert tool in registered, f'工具 {tool} 未注册，已注册: {registered}'
print(f'  ✅ 已注册 {len(tools)} 个工具')
"

echo ""

# ==================== MCP stdio 通信测试 ====================

echo "- 测试 MCP stdio 通信..."

# 创建测试笔记
$PYTHON_BIN -c "
from open_note_core.storage.note_storage import NoteStorage
storage = NoteStorage()
note = storage.create_note('MCP 测试笔记', '这是 MCP 测试内容')
print(f'NOTE_ID={note[\"id\"]}')
" > /tmp/opennote_test_id.txt

NOTE_ID=$(grep "NOTE_ID=" /tmp/opennote_test_id.txt | cut -d'=' -f2)

# 通过 stdio 发送 JSON-RPC 请求并验证响应
$PYTHON_BIN -c "
import asyncio
import json
import subprocess
import sys

async def test_mcp_stdio():
    # 启动 MCP 服务器进程
    proc = await asyncio.create_subprocess_exec(
        sys.executable, '-m', 'open_note_mcp.mcp_server',
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )

    # 发送 initialize 请求
    init_request = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '0.1.0'}
        }
    }
    proc.stdin.write((json.dumps(init_request) + '\n').encode())
    await proc.stdin.drain()

    # 读取响应
    response = await asyncio.wait_for(proc.stdout.readline(), timeout=5.0)
    resp_data = json.loads(response.decode())
    
    if 'result' in resp_data:
        print('  ✅ initialize 请求成功')
    else:
        print(f'  ❌ initialize 请求失败: {resp_data}')
        proc.terminate()
        exit(1)

    # 发送 tools/list 请求
    tools_request = {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
        'params': {}
    }
    proc.stdin.write((json.dumps(tools_request) + '\n').encode())
    await proc.stdin.drain()

    response = await asyncio.wait_for(proc.stdout.readline(), timeout=5.0)
    resp_data = json.loads(response.decode())
    
    if 'result' in resp_data and 'tools' in resp_data['result']:
        tools = [t['name'] for t in resp_data['result']['tools']]
        expected = ['search_notes', 'list_notes', 'get_note', 'create_note', 'update_note', 'delete_note']
        for tool in expected:
            assert tool in tools, f'工具 {tool} 未在 tools/list 中返回'
        print(f'  ✅ tools/list 返回 {len(tools)} 个工具')
    else:
        print(f'  ❌ tools/list 请求失败: {resp_data}')
        proc.terminate()
        exit(1)

    # 终止进程
    proc.terminate()
    try:
        await asyncio.wait_for(proc.wait(), timeout=2.0)
    except asyncio.TimeoutError:
        proc.kill()

asyncio.run(test_mcp_stdio())
"

# 清理临时文件
rm -f /tmp/opennote_test_id.txt

# 清理测试数据
rm -f "$OPENNOTE_DB_PATH"

echo ""
echo "====================================="
echo "  ✅ open-note-mcp 测试通过!"
echo "====================================="
