## Purpose

本文档面向最终用户和维护者，说明收到 `codex-lb` 的 macOS 分发包之后，应该如何安装、初始化配置并从 Terminal 直接启动服务。

这里记录的是面向人的说明和运维约定；规范性要求仍以 `spec.md` 为准。

## 为什么改成 PKG

相比 `DMG + 手动复制目录`，`PKG` 更符合这类“本地服务 + Terminal 入口”工具的分发方式：

- 安装完成后可直接在 Terminal 中运行 `codex-lb`
- 运行时文件位于系统安装目录，不要求用户手工拖拽或复制
- 用户配置和数据位于自己的 home 目录，不需要修改系统安装目录里的文件
- 适合后续继续接入签名、公证和自动化发布

## 用户会收到什么

维护者通常会分发以下文件：

- `codex-lb-macos-arm64.pkg`，用于 Apple Silicon Mac
- `codex-lb-macos-x86_64.pkg`，用于 Intel Mac
- `codex-lb-macos-<arch>.tar.gz`，用于手动安装或排障
- `codex-lb-macos-<arch>.sha256`，用于校验完整性

用户如果不确定机器架构，可以执行：

```bash
uname -m
```

常见结果：

- `arm64` 表示 Apple Silicon
- `x86_64` 表示 Intel

## 安装后的目录布局

PKG 安装完成后，关键路径如下：

- 终端命令：`/usr/local/bin/codex-lb`
- 运行时文件：`/Library/Application Support/codex-lb/`
- 新安装的默认用户配置/数据目录：`~/Library/Application Support/codex-lb/`

安装目录里的运行时文件是 PyInstaller onedir bundle 的持久副本，包含可执行文件和 `_internal/` 下的依赖、dashboard static assets、Alembic 脚本等资源。不要把 macOS 发行包改回 PyInstaller onefile：onefile 会在启动时解压到系统临时目录，长时间运行的服务可能在 macOS 清理临时目录后丢失这些资源。

兼容性说明：

- 如果用户过去已经在 `~/.codex-lb/` 下运行过旧版本，安装后的新命令仍会继续兼容这个旧目录
- 对于“第一次安装”的用户，推荐统一使用 `~/Library/Application Support/codex-lb/`

## 安装步骤

### 推荐方式：使用 PKG

1. 下载与本机架构匹配的 PKG 文件。
2. 如有需要，使用配套的 `.sha256` 校验文件完整性。
3. 双击 PKG 并完成安装。
4. 打开一个新的 Terminal 窗口。
5. 首次初始化配置时，执行：

```bash
codex-lb init
```

6. 启动服务：

```bash
codex-lb
```

7. 在浏览器打开 `http://127.0.0.1:2455`。

说明：

- `codex-lb init` 会在用户配置目录里创建 `.env.local`
- 如果用户不需要自定义配置，也可以直接运行 `codex-lb`

### 备选方式：使用 tar.gz

如果不方便分发 PKG，也可以直接分发压缩包：

```bash
mkdir -p ~/Applications/codex-lb
tar -xzf codex-lb-macos-<arch>.tar.gz -C ~/Applications/codex-lb --strip-components=1
cd ~/Applications/codex-lb
./codex-lb
```

如果压缩包来自未签名或未公证的内部构建，macOS 可能会附加 quarantine 标记。这种情况下可执行：

```bash
xattr -dr com.apple.quarantine ./codex-lb
```

## 首次配置

### 推荐方式：使用 `codex-lb init`

安装后的推荐初始化命令：

```bash
codex-lb init
```

这会在默认用户配置目录中创建：

- `~/Library/Application Support/codex-lb/.env.local`

并把安装目录里的示例配置复制过去：

- `/Library/Application Support/codex-lb/.env.example`

### 手动创建配置

如果不想使用 `codex-lb init`，也可以手动创建：

```bash
mkdir -p ~/Library/Application\ Support/codex-lb
cp "/Library/Application Support/codex-lb/.env.example" \
  ~/Library/Application\ Support/codex-lb/.env.local
```

### 旧目录兼容

如果用户之前已经使用过旧版并保留了：

- `~/.codex-lb/.env`
- `~/.codex-lb/.env.local`

新安装的 `codex-lb` 仍会兼容读取这些文件，避免升级后立刻失效。

## 常见配置项

- `CODEX_LB_DATABASE_URL`
  Fresh PKG installs 默认使用本地 SQLite，路径是 `~/Library/Application Support/codex-lb/store.db`
- `CODEX_LB_DATABASE_MIGRATE_ON_STARTUP`
  建议保持 `true`
- `CODEX_LB_UPSTREAM_BASE_URL`
  默认值为 `https://chatgpt.com/backend-api`
- `CODEX_LB_OAUTH_CALLBACK_PORT`
  默认是 `1455`，通常不应修改

适合新安装 PKG 用户的 `.env.local` 示例：

```bash
CODEX_LB_DATABASE_URL="sqlite+aiosqlite:///~/Library/Application Support/codex-lb/store.db"
CODEX_LB_DATABASE_MIGRATE_ON_STARTUP=true
```

## 首次使用流程

1. 运行 `codex-lb init`
2. 如需自定义配置，编辑 `~/Library/Application Support/codex-lb/.env.local`
3. 运行 `codex-lb`
4. 在浏览器访问 `http://127.0.0.1:2455`
5. 登录 dashboard
6. 添加 ChatGPT 账号
7. 将客户端指向本地代理地址

## 客户端接入

常见接入地址如下：

- Codex CLI：`http://127.0.0.1:2455/backend-api/codex`
- OpenAI 兼容客户端：`http://127.0.0.1:2455/v1`

Codex CLI 配置示例：

```toml
base_url = "http://127.0.0.1:2455/backend-api/codex"
```

OpenAI 兼容客户端示例：

```bash
OPENAI_BASE_URL=http://127.0.0.1:2455/v1
OPENAI_API_KEY=dummy
```

## 运行与升级

默认运行信息如下：

- 启动命令：`codex-lb`
- 安装目录：`/Library/Application Support/codex-lb/`
- 新安装默认数据目录：`~/Library/Application Support/codex-lb/`
- 兼容旧数据目录：`~/.codex-lb/`
- 服务端口：`2455`
- OAuth 回调端口：`1455`
- 健康检查：`http://127.0.0.1:2455/health`

如果 `2455` 被占用，可以改端口启动：

```bash
codex-lb --host 127.0.0.1 --port 2456
```

升级时通常只需要重新安装新的 PKG，并保留：

- `~/Library/Application Support/codex-lb/.env.local`
- `~/Library/Application Support/codex-lb/` 下的数据
- 或历史遗留的 `~/.codex-lb/` 数据目录

## 常见问题

- 安装后执行 `codex-lb` 提示命令不存在
  关闭当前 Terminal，重新打开一个新的窗口
- 不知道配置文件在哪里
  先运行 `codex-lb init`
- 浏览器打不开 dashboard
  先访问 `/health` 确认服务是否已启动
- 浏览器返回 `Frontend assets are missing`
  确认安装目录中保留了完整的 onedir runtime，尤其是 `_internal/app/static/index.html`；如果只分发或安装了单个 `codex-lb` 文件，需要重新用当前 macOS 打包流程生成 PKG/tar.gz
- `2455` 端口被占用
  换一个端口启动，并同步更新客户端地址
- OAuth 回调没有完成
  检查 `1455` 端口是否被其他程序占用
- 以前的数据不见了
  检查用户是否还在使用旧的 `~/.codex-lb/` 目录
- 收到的是未签名内部构建
  优先使用已签名并 notarized 的 PKG；如果只能用 tar.gz，可能需要手动移除 quarantine

## 维护者交付清单

给用户发包时，建议同时明确说明：

- 应使用 `arm64` 还是 `x86_64`
- 是否已签名并 notarized
- 安装后推荐先执行 `codex-lb init`
- 推荐配置目录是 `~/Library/Application Support/codex-lb/`
- 是否继续兼容旧的 `~/.codex-lb/`
- dashboard 登录凭据是否已预置
- 是否启用了 API Key 校验
- 客户端应使用的本地地址

## Related Specs

- `openspec/changes/add-macos-packaging/specs/desktop-packaging/spec.md`
