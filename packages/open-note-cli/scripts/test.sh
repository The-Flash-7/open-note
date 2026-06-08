#!/bin/bash
set -e

echo "====================================="
echo "  测试 open-note-cli"
echo "====================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# 安装依赖
echo "[信息] 安装依赖包..."
cd ../open-note-core && pip install -e . > /dev/null 2>&1 && cd ..
cd open-note-cli && pip install -e . > /dev/null 2>&1 && cd ..

# 使用临时数据库进行测试
export OPENNOTE_DB_PATH="$(mktemp /tmp/opennote_test_XXXXXX).db"

echo "[信息] 运行 CLI 测试..."
echo ""

# ==================== 基础功能测试 ====================

# 测试创建笔记
echo "- 测试创建笔记..."
OUTPUT=$(opennote note create --title "测试笔记" --content "这是测试内容" 2>&1)
if echo "$OUTPUT" | grep -q "笔记已创建"; then
    echo "  ✅ 创建成功"
else
    echo "  ❌ 创建失败: $OUTPUT"
    exit 1
fi

# 测试创建带标签和分类的笔记
echo "- 测试创建带标签和分类的笔记..."
OUTPUT=$(opennote note create --title "工作笔记" --content "工作内容" --category "工作" --tags "重要,待办" 2>&1)
if echo "$OUTPUT" | grep -q "笔记已创建"; then
    echo "  ✅ 创建成功"
else
    echo "  ❌ 创建失败: $OUTPUT"
    exit 1
fi

# 测试列出笔记
echo "- 测试列出笔记..."
OUTPUT=$(opennote note list 2>&1)
if echo "$OUTPUT" | grep -q "测试笔记" && echo "$OUTPUT" | grep -q "工作笔记"; then
    echo "  ✅ 列表包含所有笔记"
else
    echo "  ❌ 列表中未找到笔记"
    exit 1
fi

# 测试分类过滤
echo "- 测试分类过滤..."
OUTPUT=$(opennote note list --category "工作" 2>&1)
if echo "$OUTPUT" | grep -q "工作笔记" && ! echo "$OUTPUT" | grep -q "测试笔记"; then
    echo "  ✅ 分类过滤正确"
else
    echo "  ❌ 分类过滤失败"
    exit 1
fi

# 测试搜索笔记
echo "- 测试搜索笔记..."
OUTPUT=$(opennote note search "测试内容" 2>&1)
if echo "$OUTPUT" | grep -q "测试笔记"; then
    echo "  ✅ 搜索成功"
else
    echo "  ❌ 搜索失败"
    exit 1
fi

# 测试查看笔记详情
echo "- 测试查看笔记详情..."
# 获取最近创建的笔记 ID（从创建输出中提取）
CREATE_OUTPUT=$(opennote note create --title "详情测试" --content "用于测试详情" 2>&1)
NOTE_ID=$(echo "$CREATE_OUTPUT" | grep -o '[a-f0-9-]\{36\}' | head -1)
OUTPUT=$(opennote note show "$NOTE_ID" 2>&1)
if echo "$OUTPUT" | grep -q "标题:"; then
    echo "  ✅ 查看成功"
else
    echo "  ❌ 查看失败"
    exit 1
fi

# ==================== 编辑和删除测试 ====================

# 测试编辑笔记
echo "- 测试编辑笔记..."
OUTPUT=$(opennote note edit "$NOTE_ID" --title "编辑后的标题" 2>&1)
if echo "$OUTPUT" | grep -q "笔记已更新"; then
    echo "  ✅ 编辑成功"
else
    echo "  ❌ 编辑失败: $OUTPUT"
    exit 1
fi

# 验证编辑结果
echo "- 验证编辑结果..."
OUTPUT=$(opennote note show "$NOTE_ID" 2>&1)
if echo "$OUTPUT" | grep -q "编辑后的标题"; then
    echo "  ✅ 编辑结果正确"
else
    echo "  ❌ 编辑结果不正确"
    exit 1
fi

# 测试删除笔记
echo "- 测试删除笔记..."
OUTPUT=$(opennote note delete "$NOTE_ID" 2>&1)
if echo "$OUTPUT" | grep -q "笔记已删除"; then
    echo "  ✅ 删除成功"
else
    echo "  ❌ 删除失败: $OUTPUT"
    exit 1
fi

# 验证删除结果
echo "- 验证删除结果..."
OUTPUT=$(opennote note list 2>&1)
if ! echo "$OUTPUT" | grep -q "编辑后的标题"; then
    echo "  ✅ 删除结果正确"
else
    echo "  ❌ 删除后笔记仍存在"
    exit 1
fi

# ==================== 错误处理测试 ====================

# 测试查看不存在的笔记
echo "- 测试查看不存在的笔记..."
OUTPUT=$(opennote note show "non-existent-id" 2>&1)
if echo "$OUTPUT" | grep -q "不存在"; then
    echo "  ✅ 错误处理正确"
else
    echo "  ❌ 错误处理失败"
    exit 1
fi

# 测试删除不存在的笔记
echo "- 测试删除不存在的笔记..."
OUTPUT=$(opennote note delete "non-existent-id" 2>&1)
if echo "$OUTPUT" | grep -q "不存在"; then
    echo "  ✅ 错误处理正确"
else
    echo "  ❌ 错误处理失败"
    exit 1
fi

# ==================== MCP 命令测试 ====================

# 测试 MCP 检查命令
echo "- 测试 MCP 检查命令..."
OUTPUT=$(opennote mcp inspect 2>&1)
if echo "$OUTPUT" | grep -q "search_notes" && echo "$OUTPUT" | grep -q "list_notes"; then
    echo "  ✅ MCP 检查成功"
else
    echo "  ❌ MCP 检查失败"
    exit 1
fi

# ==================== 中文支持测试 ====================

# 测试中文内容
echo "- 测试中文内容..."
OUTPUT=$(opennote note create --title "中文标题测试" --content "这是一段中文内容，包含特殊字符：！@#￥%……&*（）" 2>&1)
if echo "$OUTPUT" | grep -q "笔记已创建"; then
    echo "  ✅ 中文支持正确"
else
    echo "  ❌ 中文支持失败"
    exit 1
fi

# 清理测试数据
rm -f "$OPENNOTE_DB_PATH"

echo ""
echo "====================================="
echo "  ✅ open-note-cli 测试通过!"
echo "====================================="
