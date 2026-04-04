## Purpose

本文档给最终用户使用，说明在收到 `codex-lb` 的 macOS 分发包后，应如何安装、配置并开始使用。

适用场景：

- 维护者将 DMG 或压缩包发给内部用户
- 团队内部做小范围试用或正式发布
- 需要给最终用户一份可直接照着操作的说明

规范性要求仍然以 `spec.md` 为准；这里仅提供面向人的安装、配置和运维说明。

## 用户会收到什么

维护者通常会提供下面这些与架构对应的文件：

- `codex-lb-macos-arm64.dmg`，用于 Apple Silicon Mac
- `codex-lb-macos-x86_64.dmg`，用于 Intel Mac
- `codex-lb-macos-<arch>.tar.gz`，用于手动解压安装
- `codex-lb-macos-<arch>.sha256`，用于校验下载文件完整性

如果用户不确定自己机器的架构，可以在终端执行：

```bash
uname -m
```

常见结果：

- `arm64` 表示 Apple Silicon
- `x86_64` 表示 Intel

安装包目录内通常包含：

- `codex-lb` 可执行文件
- `.env.example` 示例配置文件
- `README.txt` 简版说明

最终用户不需要额外安装 Python、`uv`、Bun，也不需要保留源码仓库。

## 安装步骤

### 推荐方式：使用 DMG

1. 下载与本机架构匹配的 DMG 文件。
2. 如有需要，使用配套的 `.sha256` 文件校验完整性。
3. 打开 DMG，将内容复制到本地可写目录，例如 `~/Applications/codex-lb/`。
4. 打开终端并进入该目录。
5. 启动服务：

```bash
./codex-lb --host 127.0.0.1 --port 2455
```

6. 在浏览器打开 `http://127.0.0.1:2455`。

优先推荐 DMG，因为签名和 notarization 都是围绕分发产物完成的，普通用户的打开体验更稳定。

### 备选方式：使用 tar.gz

如果不方便分发 DMG，也可以直接发压缩包：

```bash
mkdir -p ~/Applications/codex-lb
tar -xzf codex-lb-macos-<arch>.tar.gz -C ~/Applications/codex-lb --strip-components=1
cd ~/Applications/codex-lb
./codex-lb --host 127.0.0.1 --port 2455
```

如果压缩包来自未签名的内部构建，macOS 可能会给文件打上 quarantine 标记。这种情况下可执行：

```bash
xattr -dr com.apple.quarantine ./codex-lb
```

## 首次配置

打包后的可执行文件会从自身所在目录读取 `.env` 和 `.env.local`。

推荐首次启动前执行：

```bash
cp .env.example .env.local
```

多数用户无需修改太多配置，默认值已经适合单机本地使用。只有在维护者明确要求时，才需要改动配置。

### 常见配置项

- `CODEX_LB_DATABASE_URL`
  默认是本地 SQLite，路径为 `~/.codex-lb/store.db`
- `CODEX_LB_DATABASE_MIGRATE_ON_STARTUP`
  默认应保持 `true`，这样升级后会自动执行数据库迁移
- `CODEX_LB_UPSTREAM_BASE_URL`
  默认值为 `https://chatgpt.com/backend-api`
- `CODEX_LB_OAUTH_CALLBACK_PORT`
  默认是 `1455`，通常不应修改

适合个人本地运行的 `.env.local` 示例：

```bash
CODEX_LB_DATABASE_URL=sqlite+aiosqlite:///~/.codex-lb/store.db
CODEX_LB_DATABASE_MIGRATE_ON_STARTUP=true
```

## 首次使用流程

1. 启动 `codex-lb`。
2. 在浏览器访问 `http://127.0.0.1:2455`。
3. 如果维护者启用了 dashboard 登录保护，先用分发时提供的密码或 TOTP 完成登录。
4. 在 dashboard 中添加 ChatGPT 账号。
5. 等待账号状态变成可用。
6. 将你的客户端指向本地代理地址。

## 客户端如何接入

常见接入地址如下：

- Codex CLI：`http://127.0.0.1:2455/backend-api/codex`
- OpenAI 兼容客户端：`http://127.0.0.1:2455/v1`

Codex CLI 常见配置示例：

```toml
base_url = "http://127.0.0.1:2455/backend-api/codex"
```

OpenAI 兼容客户端示例：

```bash
OPENAI_BASE_URL=http://127.0.0.1:2455/v1
OPENAI_API_KEY=dummy
```

说明：

- 如果维护者没有启用 API Key 校验，兼容客户端通常可使用任意占位字符串作为 `API key`
- 如果维护者启用了 API Key 校验，用户需要先在 dashboard 中创建 API key，再将该 key 配置到自己的客户端

## 运行与升级说明

默认运行信息如下：

- 数据目录：`~/.codex-lb/`
- 服务端口：`2455`
- OAuth 回调端口：`1455`
- 健康检查地址：`http://127.0.0.1:2455/health`

如果本机 `2455` 端口被占用，可以改成其他端口启动：

```bash
./codex-lb --host 127.0.0.1 --port 2456
```

如果修改了端口，所有客户端地址也要同步改成新端口。

升级时，通常只需要替换分发目录中的程序文件，并保留：

- `.env.local`
- `~/.codex-lb/` 下的数据

## 常见问题与故障处理

- 浏览器打不开 dashboard
  先确认进程仍在运行，再访问 `/health` 检查服务是否正常
- `2455` 端口已被占用
  改用其他端口启动，并同步更新客户端配置
- OAuth 登录回调没有完成
  确认本机 `1455` 端口没有被其他程序占用
- 更换机器或误删文件后数据库异常
  仅在确认要“从头开始”时才删除 `~/.codex-lb/` 下的 SQLite 数据文件
- 客户端连不上代理
  确认客户端地址使用的是 `127.0.0.1`，并且端口与当前启动参数一致
- 收到的是未签名内部构建
  可能需要手动移除 quarantine 标记后才能运行

## 维护者交付清单

将分发包交给用户时，维护者最好同时明确告知：

- 应使用 `arm64` 还是 `x86_64` 版本
- 对应的 `.sha256` 校验文件
- 当前构建是否已签名并 notarized
- dashboard 登录凭据是否已预先配置
- 是否默认启用了 API Key 校验
- 用户最终应配置到客户端里的确切地址

## Related Specs

- `openspec/changes/add-macos-packaging/specs/desktop-packaging/spec.md`
