# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

"""OpenNote MCP Server"""
import argparse
import asyncio
import json
import sys
from mcp.server.fastmcp import FastMCP
from open_note_core.storage.note_storage import NoteStorage
from open_note_core.version_checker import check_update

try:
    import importlib.metadata
    __version__ = importlib.metadata.version("open-note-mcp")
except Exception:
    __version__ = "0.2.0"
__protocol_version__ = "2024-11-05"

server = FastMCP(name="open-note-mcp")
storage = NoteStorage()


@server.tool(name="search_notes")
async def search_notes(
    query: str,
    limit: int = 10,
    category: str = None,
    tags: list = None,
    favorites_only: bool = False,
) -> str:
    """搜索笔记。按标题、内容或摘要搜索。支持按分类、标签和收藏过滤。"""
    try:
        notes = storage.search_notes(query, limit=limit, category=category, tags=tags, favorites_only=favorites_only)
        return json.dumps(notes, ensure_ascii=False)
    except Exception as e:
        return f"搜索失败: {str(e)}"


@server.tool(name="list_notes")
async def list_notes(limit: int = 10, category: str = None, favorites_only: bool = False) -> str:
    """列出笔记。默认按更新时间倒序排列。支持按分类和收藏过滤。"""
    try:
        notes = storage.get_notes(limit=limit, category=category, is_favorite=favorites_only)
        return json.dumps(notes, ensure_ascii=False)
    except Exception as e:
        return f"获取笔记列表失败: {str(e)}"


@server.tool(name="get_note")
async def get_note(note_id: str) -> str:
    """查看笔记详情。返回笔记的完整内容。"""
    try:
        note = storage.get_note(note_id)
        if note:
            return json.dumps(note, ensure_ascii=False)
        return f"笔记 {note_id} 不存在"
    except Exception as e:
        return f"获取笔记失败: {str(e)}"


@server.tool(name="create_note")
async def create_note(title: str, content: str = "", category: str = None, tags: list = None, format: str = "markdown") -> str:
    """创建笔记。返回创建的笔记详情。"""
    try:
        note = storage.create_note(title, content, category=category, tags=tags, format=format)
        return json.dumps(note, ensure_ascii=False)
    except Exception as e:
        return f"创建笔记失败: {str(e)}"


@server.tool(name="update_note")
async def update_note(note_id: str, title: str = None, content: str = None) -> str:
    """编辑笔记。可以更新标题和/或内容。返回更新后的笔记详情。"""
    try:
        note = storage.update_note(note_id, title=title, content=content)
        if note:
            return json.dumps(note, ensure_ascii=False)
        return f"笔记 {note_id} 不存在"
    except Exception as e:
        return f"更新笔记失败: {str(e)}"


@server.tool(name="delete_note")
async def delete_note(note_id: str) -> str:
    """删除笔记（软删除）。删除后可在回收站恢复。"""
    try:
        success = storage.delete_note(note_id)
        if success:
            return f"笔记 {note_id} 已删除"
        return f"笔记 {note_id} 不存在"
    except Exception as e:
        return f"删除笔记失败: {str(e)}"


def print_help():
    """打印帮助信息"""
    help_text = f"""
OpenNote MCP Server - Model Context Protocol 服务

版本: {__version__}
MCP 协议版本: {__protocol_version__}
传输方式: stdio

用法:
  open-note-mcp [命令] [选项]

命令:
  server          启动 MCP 服务器（stdio 传输，默认行为）
  tools           列出所有可用的 MCP 工具
  status          检查服务器配置和状态

选项:
  -h, --help      显示此帮助信息并退出
  -v, --version   显示版本信息并退出

示例:
  open-note-mcp              # 启动 MCP 服务器
  open-note-mcp server       # 启动 MCP 服务器（同上）
  open-note-mcp tools        # 列出可用工具
  open-note-mcp --version    # 查看版本
"""
    print(help_text)


def print_version():
    """打印版本信息"""
    print(f"open-note-mcp {__version__}")
    print(f"MCP Protocol: {__protocol_version__}")


def list_tools():
    """列出所有可用的 MCP 工具"""
    tools = server._tool_manager.list_tools()
    print(f"\n可用工具 ({len(tools)} 个):\n")
    for tool in tools:
        print(f"  {tool.name}")
        if tool.description:
            print(f"    {tool.description}")
        print()


def check_status():
    """检查服务器状态"""
    # 检查是否有可用更新
    mcp_update = check_update("open-note-mcp")
    version_str = __version__
    if mcp_update:
        version_str = f"{__version__} (最新: {mcp_update['latest']})"

    print(f"\nOpenNote MCP Server 状态")
    print(f"  版本: {version_str}")
    print(f"  MCP 协议版本: {__protocol_version__}")
    print(f"  传输方式: stdio")
    print(f"  工具数量: {len(server._tool_manager.list_tools())}")
    
    # 检查存储层
    try:
        db_path = storage.db_path
        print(f"  数据库路径: {db_path}")
        print(f"  存储状态: 正常")
    except Exception as e:
        print(f"  存储状态: 异常 - {e}")
    
    # 显示更新提示
    if mcp_update:
        print(f"\n  ✨ 新版本可用: {mcp_update['current']} → {mcp_update['latest']}")
        print(f"     运行: pip install --upgrade open-note-mcp")
    
    print()


def main():
    """主入口函数"""
    parser = argparse.ArgumentParser(
        description="OpenNote MCP Server - Model Context Protocol 服务",
        add_help=False,
    )
    parser.add_argument(
        "-h", "--help",
        action="store_true",
        help="显示帮助信息",
    )
    parser.add_argument(
        "-v", "--version",
        action="store_true",
        help="显示版本信息",
    )
    parser.add_argument(
        "command",
        nargs="?",
        default="server",
        choices=["server", "tools", "status"],
        help="执行的命令 (默认: server)",
    )

    args = parser.parse_args()

    if args.help:
        print_help()
        sys.exit(0)

    if args.version:
        print_version()
        sys.exit(0)

    if args.command == "tools":
        list_tools()
        sys.exit(0)

    if args.command == "status":
        check_status()
        sys.exit(0)

    # 默认行为：启动 MCP 服务器
    server.run(transport="stdio")


if __name__ == "__main__":
    main()
