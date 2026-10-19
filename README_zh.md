# Simulator Learning

[English](README.md)

这是一个长期维护的开源仿真器学习与研究仓库，关注物理仿真、数值方法、机器人与具身智能仿真、CAE 和可微分仿真。

仓库将官方源码、学习文档、小型实践代码和研究实验分层管理，避免学习内容与第三方源码相互污染。

## 仓库结构

```text
Simulators/   以 Git Submodule 固定的官方上游源码
Docs/         公共理论与各仿真器独立的 MkDocs 文档
Examples/     小型学习代码与源码验证程序
Experiments/  用于回答技术问题的可复现实验
```

`Simulators/<name>`、`Docs/<name>` 和 `Examples/<name>` 始终使用同一个 slug。

## 仿真器

| 仿真器 | 上游仓库 | 本地路径 | 固定提交 | 主要语言 | 学习状态 |
| --- | --- | --- | --- | --- | --- |
| MuJoCo | [google-deepmind/mujoco](https://github.com/google-deepmind/mujoco) | `Simulators/mujoco` | `526583e5b7c3` | C/C++、Python | 计划中 |
| Newton | [newton-physics/newton](https://github.com/newton-physics/newton) | `Simulators/newton` | `756912b1f716` | Python、GPU Kernel | 计划中 |
| Genesis World | [Genesis-Embodied-AI/genesis-world](https://github.com/Genesis-Embodied-AI/genesis-world) | `Simulators/genesis` | `50a2aa19cba6` | Python | 计划中 |
| OpenCourant | [OpenCourant/OpenCourant](https://github.com/OpenCourant/OpenCourant) | `Simulators/opencourant` | `b19ec63f3724` | Fortran、C/C++ | 计划中 |
| PeriDyno | [peridyno/peridyno](https://github.com/peridyno/peridyno) | `Simulators/peridyno` | `480aa9976d08` | C++、CUDA | 计划中 |
| PPF Contact Solver | [st-tech/ppf-contact-solver](https://github.com/st-tech/ppf-contact-solver) | `Simulators/ppf-contact-solver` | `d6a1ace41841` | Rust、Python | 计划中 |
| PositionBasedDynamics | [InteractiveComputerGraphics/PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics) | `Simulators/position-based-dynamics` | `10a70bc146a9` | C++、Python | 计划中 |

表中的提交均来自各 Submodule 的真实 checkout。OpenCourant 是已删除 OpenRadioss 项目的社区开源后继。

## 快速开始

首次克隆时同时拉取 Submodule：

```bash
git clone --recurse-submodules <repository>
```

OpenCourant 的部分资产使用 Git LFS。如需这些资产，请在克隆前安装并初始化 Git LFS；本次仓库初始化不会在主仓库中启用 Git LFS。

普通克隆后补齐 Submodule，或主仓库更新后同步：

```bash
git pull
git submodule update --init --recursive
git submodule status
```

升级仿真器时，应在对应 Submodule 中显式获取并 checkout 经过确认的上游版本，验证相关文档和示例后，再由主仓库记录新的 gitlink。仓库不会自动追踪上游最新提交。

### 文档

```bash
conda env create -f Docs/environment.yml
conda activate simulator-docs
cd Docs/mujoco
mkdocs serve       # 或执行 mkdocs build
```

`Docs/` 下每个目录都是独立的 MkDocs 项目，Markdown 文件才是长期知识资产。

### 示例

Python 环境按仿真器隔离，例如：

```bash
conda env create -f Examples/mujoco/environment.yml
conda activate mujoco
```

`Examples/xmake.lua` 是未来自编 C、C++、CUDA 和 Fortran 示例的统一入口，目前尚未定义 target。生成内容统一写入顶层 `build/examples/`。官方源码仍使用各自的上游构建系统；若上游支持外部构建，则使用 `build/simulators/<slug>/`。

## 设计原则

1. 通过 Git Submodule 隔离上游源码。
2. 通过固定 commit 保证仿真器版本可复现。
3. 以 Markdown 作为文档唯一事实来源。
4. 使用 Conda 为不同仿真器隔离 Python 环境。
5. Xmake 只管理自编的编译型语言示例。
6. Example 用于学习单一能力，Experiment 用于回答技术问题。
7. Docs 与 Examples 使用仓库相对路径相互引用。
8. 在工具支持时，将生成内容集中到顶层 `build/`：官方仿真器使用 `build/simulators/<slug>/`，自编示例使用 `build/examples/`，文档站点使用 `build/docs/<slug>/`。
9. `.gitignore` 只对顶层 `/build/` 和不可避免的缓存、默认 `site/` 等产物做精确兜底，不使用 `**/build/` 隐藏任意位置的构建目录，使违反目录约定的产物能够被及时发现。
10. 官方仿真器始终保留其上游构建系统；若上游不支持外部构建目录，则记录例外，而不是修改第三方源码或用 Xmake 强行统一。

大型数据集、模型权重、大型网格、二进制文件、构建产物、视频、缓存和 Conda 环境本体不应提交到 Git。未来确有需求时再单独评估 Git LFS。

仓库规范见 [CONTRIBUTING.md](CONTRIBUTING.md)。
