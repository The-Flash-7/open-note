# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

"""OpenNote 版本检查模块"""
import json
import urllib.request
import urllib.error
import importlib.metadata
from typing import Optional
from packaging.version import Version


PYPI_API_URL = "https://pypi.org/pypi/{package}/json"
TIMEOUT = 2  # 秒


def get_current_version(package_name: str) -> str:
    """获取已安装包的当前版本"""
    return importlib.metadata.version(package_name)


def get_latest_version(package_name: str) -> Optional[str]:
    """从 PyPI 获取包的最新版本"""
    try:
        url = PYPI_API_URL.format(package=package_name)
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            data = json.loads(response.read().decode())
            return data.get("info", {}).get("version")
    except Exception:
        return None


def is_package_installed(package_name: str) -> bool:
    """检查包是否已安装"""
    try:
        importlib.metadata.version(package_name)
        return True
    except importlib.metadata.PackageNotFoundError:
        return False


def check_update(package_name: str) -> Optional[dict]:
    """
    检查指定包是否有可用更新

    返回:
        {"package": str, "current": str, "latest": str} 如果有更新
        None 如果已是最新或检查失败
    """
    try:
        current = get_current_version(package_name)
    except importlib.metadata.PackageNotFoundError:
        return None

    latest = get_latest_version(package_name)
    if latest is None:
        return None

    # 使用 packaging.version 进行正确的语义版本比较
    if Version(latest) > Version(current):
        return {
            "package": package_name,
            "current": current,
            "latest": latest,
        }
    return None


def check_all_opennote_updates() -> list[dict]:
    """
    检查所有 OpenNote 包的更新

    返回:
        需要更新的包列表 [{"package": str, "current": str, "latest": str}, ...]
    """
    packages = ["open-note-core", "open-note-cli", "open-note-mcp"]
    updates = []

    for pkg in packages:
        if is_package_installed(pkg):
            update = check_update(pkg)
            if update:
                updates.append(update)

    return updates


def format_update_message(updates: list[dict]) -> str:
    """
    格式化更新提示信息

    返回:
        格式化的更新消息字符串，如果没有更新则返回空字符串
    """
    if not updates:
        return ""

    lines = ["\n✨ 新版本可用:"]
    upgrade_packages = []

    for update in updates:
        lines.append(
            f"   {update['package']}: {update['current']} → {update['latest']}"
        )
        upgrade_packages.append(update["package"])

    lines.append(f"   运行: pip install --upgrade {' '.join(upgrade_packages)}\n")

    return "\n".join(lines)
