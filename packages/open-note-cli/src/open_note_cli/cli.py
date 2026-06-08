# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

"""OpenNote CLI - 跨平台笔记管理工具"""
import typer
import json
import subprocess
import sys
import importlib.metadata
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from open_note_core.storage.note_storage import NoteStorage
from open_note_core.version_checker import check_all_opennote_updates, format_update_message

try:
    __version__ = importlib.metadata.version("open-note-cli")
except Exception:
    __version__ = "0.3.0"

app = typer.Typer(
    name="opennote",
    help="OpenNote CLI - 跨平台笔记管理工具",
    add_completion=False,
    invoke_without_command=True,
)
console = Console()

# 初始化存储层
storage = NoteStorage()


@app.callback()
def version_check_callback(
    version: bool = typer.Option(False, "--version", "-v", help="显示版本信息"),
):
    """每次执行命令前检查版本更新"""
    if version:
        print(f"opennote {__version__}")
        raise typer.Exit()
    
    try:
        updates = check_all_opennote_updates()
        message = format_update_message(updates)
        if message:
            console.print(message)
    except Exception:
        pass

# ==================== 笔记管理命令 ====================

note_app = typer.Typer(help="笔记管理")
app.add_typer(note_app, name="note")


@note_app.command("list")
def list_notes(
    limit: int = typer.Option(10, "--limit", "-l", help="显示数量"),
    category: str = typer.Option(None, "--category", "-c", help="按分类过滤"),
    favorites_only: bool = typer.Option(False, "--favorites", "-f", help="只显示收藏"),
):
    """列出笔记"""
    try:
        notes = storage.get_notes(limit=limit, category=category, is_favorite=favorites_only)
        if not notes:
            console.print(Panel("没有找到笔记", title="提示", border_style="yellow"))
            return

        table = Table(title="笔记列表")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("标题", style="green")
        table.add_column("分类", style="yellow")
        table.add_column("更新时间", style="dim")
        table.add_column("收藏", style="red")

        for note in notes:
            updated_at = note.get("updated_at", "")
            if isinstance(updated_at, int):
                updated_at = datetime.fromtimestamp(updated_at / 1000).strftime("%Y-%m-%d %H:%M")

            table.add_row(
                note["id"][:8],
                note["title"][:30],
                note.get("category", "-") or "-",
                str(updated_at),
                "★" if note.get("is_favorite") else "",
            )

        console.print(table)
        console.print(f"\n共 {len(notes)} 条笔记")
    except Exception as e:
        console.print(f"[red]获取笔记列表失败: {e}[/red]")


@note_app.command("show")
def show_note(note_id: str):
    """查看笔记详情"""
    try:
        note = storage.get_note(note_id)
        if not note:
            console.print(Panel(f"笔记 {note_id} 不存在", title="错误", border_style="red"))
            return

        console.print(Panel(
            f"[bold green]标题:[/bold green] {note['title']}\n"
            f"[bold green]分类:[/bold green] {note.get('category', '-') or '-'}\n"
            f"[bold green]标签:[/bold green] {note.get('tags', '-') or '-'}\n"
            f"[bold green]字数:[/bold green] {note.get('word_count', 0)}\n\n"
            f"[bold]内容:[/bold]\n{note.get('content', '')}",
            title=f"笔记详情 ({note['id'][:8]})",
            border_style="blue",
        ))
    except Exception as e:
        console.print(f"[red]获取笔记失败: {e}[/red]")


@note_app.command("create")
def create_note(
    title: str = typer.Option(..., "--title", "-t", help="笔记标题"),
    content: str = typer.Option(None, "--content", "-c", help="笔记内容（不传则打开编辑器）"),
    category: str = typer.Option(None, "--category", help="分类"),
    tags: str = typer.Option(None, "--tags", help="标签（逗号分隔）"),
):
    """创建笔记"""
    try:
        if content is None:
            content = typer.edit()
            if not content:
                console.print("[yellow]已取消创建[/yellow]")
                return

        tags_list = [t.strip() for t in tags.split(",")] if tags else None
        note = storage.create_note(title, content, category=category, tags=tags_list)

        console.print(Panel(
            f"[green]笔记已创建[/green]\n"
            f"ID: {note['id']}\n"
            f"标题: {note['title']}",
            title="成功",
            border_style="green",
        ))
    except Exception as e:
        console.print(f"[red]创建笔记失败: {e}[/red]")


@note_app.command("edit")
def edit_note(
    note_id: str,
    title: str = typer.Option(None, "--title", "-t", help="新标题"),
    content: str = typer.Option(None, "--content", "-c", help="新内容（不传则打开编辑器）"),
):
    """编辑笔记"""
    try:
        existing = storage.get_note(note_id)
        if not existing:
            console.print(Panel(f"笔记 {note_id} 不存在", title="错误", border_style="red"))
            return

        if content is None and title is None:
            content = typer.edit(text=existing.get("content", ""))
            if not content:
                console.print("[yellow]已取消编辑[/yellow]")
                return

        note = storage.update_note(note_id, title=title, content=content)
        if note:
            console.print(Panel("[green]笔记已更新[/green]", title="成功", border_style="green"))
        else:
            console.print("[red]更新失败[/red]")
    except Exception as e:
        console.print(f"[red]编辑笔记失败: {e}[/red]")


@note_app.command("delete")
def delete_note(note_id: str):
    """删除笔记"""
    try:
        success = storage.delete_note(note_id)
        if success:
            console.print(Panel("[green]笔记已删除[/green]", title="成功", border_style="green"))
        else:
            console.print(Panel(f"笔记 {note_id} 不存在", title="错误", border_style="red"))
    except Exception as e:
        console.print(f"[red]删除笔记失败: {e}[/red]")


@note_app.command("search")
def search_notes(
    query: str,
    limit: int = typer.Option(10, "--limit", "-l", help="显示数量"),
    category: str = typer.Option(None, "--category", "-c", help="按分类过滤"),
):
    """搜索笔记"""
    try:
        notes = storage.search_notes(query, limit=limit, category=category)
        if not notes:
            console.print(Panel(f"没有找到包含 '{query}' 的笔记", title="搜索结果", border_style="yellow"))
            return

        table = Table(title=f"搜索结果: {query}")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("标题", style="green")
        table.add_column("分类", style="yellow")
        table.add_column("更新时间", style="dim")

        for note in notes:
            updated_at = note.get("updated_at", "")
            if isinstance(updated_at, int):
                updated_at = datetime.fromtimestamp(updated_at / 1000).strftime("%Y-%m-%d %H:%M")

            table.add_row(
                note["id"][:8],
                note["title"][:30],
                note.get("category", "-") or "-",
                str(updated_at),
            )

        console.print(table)
        console.print(f"\n找到 {len(notes)} 条结果")
    except Exception as e:
        console.print(f"[red]搜索失败: {e}[/red]")


# ==================== MCP 服务命令 ====================

mcp_app = typer.Typer(help="MCP 服务管理")
app.add_typer(mcp_app, name="mcp")


@mcp_app.command("start")
def mcp_start():
    """启动 MCP 服务器（stdio 模式）"""
    import shutil

    # 检查 open-note-mcp 是否已安装
    mcp_command = shutil.which("open-note-mcp")
    
    if mcp_command is None:
        console.print(Panel(
            "[bold yellow]⚠️  open-note-mcp 未安装[/bold yellow]\n\n"
            "OpenNote CLI 需要 open-note-mcp 包来启动 MCP 服务器。\n\n"
            "[bold]安装方式 1：自动安装[/bold]\n"
            "  运行: pip install open-note-mcp\n\n"
            "[bold]安装方式 2：手动安装[/bold]\n"
            "  1. 确保 Python 3.10+ 已安装\n"
            "  2. 运行: pip install open-note-mcp\n"
            "  3. 验证: open-note-mcp --version\n\n"
            "[dim]详细文档: https://pypi.org/project/open-note-mcp/[/dim]",
            title="MCP 服务器未安装",
            border_style="yellow",
        ))
        console.print("")
        
        # 询问是否自动安装
        if typer.confirm("是否自动安装 open-note-mcp？"):
            console.print("\n[yellow]正在安装 open-note-mcp...[/yellow]")
            try:
                result = subprocess.run(
                    [sys.executable, "-m", "pip", "install", "open-note-mcp"],
                    capture_output=True,
                    text=True,
                    timeout=120,
                )
                
                if result.returncode == 0:
                    console.print("[green]✅ open-note-mcp 安装成功[/green]\n")
                    # 重新检查命令是否可用
                    mcp_command = shutil.which("open-note-mcp")
                    if mcp_command is None:
                        console.print("[yellow]⚠️  安装完成但命令不可用，请重启终端后重试[/yellow]")
                        return
                else:
                    console.print(Panel(
                        f"[red]安装失败[/red]\n\n"
                        f"错误信息:\n{result.stderr}\n\n"
                        "[bold]请手动安装:[/bold]\n"
                        f"  pip install open-note-mcp",
                        title="安装错误",
                        border_style="red",
                    ))
                    return
            except subprocess.TimeoutExpired:
                console.print(Panel(
                    "[red]安装超时[/red]\n\n"
                    "网络可能较慢，请手动安装:\n"
                    "  pip install open-note-mcp",
                    title="安装超时",
                    border_style="red",
                ))
                return
            except Exception as e:
                console.print(Panel(
                    f"[red]安装异常: {e}[/red]\n\n"
                    "请手动安装:\n"
                    "  pip install open-note-mcp",
                    title="安装错误",
                    border_style="red",
                ))
                return
        else:
            console.print("\n[yellow]已取消安装，请手动运行: pip install open-note-mcp[/yellow]")
            return

    console.print(Panel(
        "正在启动 MCP 服务器...\n"
        "[dim]按 Ctrl+C 停止服务[/dim]",
        title="MCP 服务器",
        border_style="blue",
    ))
    try:
        subprocess.run([mcp_command])
    except KeyboardInterrupt:
        console.print("\n[yellow]服务已停止[/yellow]")


@mcp_app.command("inspect")
def mcp_inspect():
    """检查 MCP 服务配置"""
    console.print(Panel(
        "[bold]OpenNote MCP Server[/bold]\n\n"
        "工具列表:\n"
        "  • search_notes - 搜索笔记\n"
        "  • list_notes - 列出笔记\n"
        "  • get_note - 查看笔记详情\n"
        "  • create_note - 创建笔记\n"
        "  • update_note - 编辑笔记\n"
        "  • delete_note - 删除笔记\n\n"
        f"数据库路径: {storage.db_path}",
        title="MCP 服务配置",
        border_style="green",
    ))


# ==================== 配置命令 ====================

config_app = typer.Typer(help="配置管理")
app.add_typer(config_app, name="config")


@config_app.command("get")
def config_get():
    """查看当前配置"""
    console.print(Panel(
        f"数据库路径: {storage.db_path}",
        title="当前配置",
        border_style="blue",
    ))


# ==================== 入口 ====================

if __name__ == "__main__":
    app()
