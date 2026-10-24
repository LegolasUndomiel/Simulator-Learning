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
| MuJoCo | [google-deepmind/mujoco](https://github.com/google-deepmind/mujoco) | `Simulators/mujoco` | `526583e5b7c3` | C/C++、Python | 已构建并通过测试 |
| Newton | [newton-physics/newton](https://github.com/newton-physics/newton) | `Simulators/newton` | `756912b1f716` | Python、GPU Kernel | 已构建；测试未跑完 |
| Genesis World | [Genesis-Embodied-AI/genesis-world](https://github.com/Genesis-Embodied-AI/genesis-world) | `Simulators/genesis` | `50a2aa19cba6` | Python | 已构建并通过测试 |
| OpenCourant | [OpenCourant/OpenCourant](https://github.com/OpenCourant/OpenCourant) | `Simulators/opencourant` | `b19ec63f3724` | Fortran、C/C++ | 已构建并通过测试 |
| PeriDyno | [peridyno/peridyno](https://github.com/peridyno/peridyno) | `Simulators/peridyno` | `480aa9976d08` | C++、CUDA | 已构建并通过测试 |
| PPF Contact Solver | [st-tech/ppf-contact-solver](https://github.com/st-tech/ppf-contact-solver) | `Simulators/ppf-contact-solver` | `d6a1ace41841` | Rust、Python | 已构建并通过测试 |
| PositionBasedDynamics | [InteractiveComputerGraphics/PositionBasedDynamics](https://github.com/InteractiveComputerGraphics/PositionBasedDynamics) | `Simulators/position-based-dynamics` | `10a70bc146a9` | C++、Python | 已构建（上游无测试） |

表中的提交均来自各 Submodule 的真实 checkout。OpenCourant 是已删除 OpenRadioss 项目的社区开源后继。

上表状态均已在 Windows 上验证：使用各模拟器的官方工具链编译所固定的提交，并运行其官方测试套件；各模拟器的命令、结果与已知上游问题记录在 [`Experiments/build-verification/README.md`](Experiments/build-verification/README.md)。

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

### 使用 Xmake 构建

Xmake 是仓库统一的本地构建入口。默认配置只需要 Visual Studio 2022 和 Git；CUDA、Intel oneAPI 与 Python 仅在显式启用对应目标时需要。

```powershell
xmake f -P . -y -c -m release # 重置配置并选择根项目：PBD + MuJoCo
                           # 若首次恢复依赖后提示重新配置，请再运行一次
xmake -j 12                # 默认目标：PBD 库 + 16 个 demo，
                           # MuJoCo 核心 + 插件 + 样例
# 配置时添加 --with_mujoco_tests=y 可启用测试及 benchmark 程序。
xmake f -y -c -m release --with_peridyno=y --peridyno_cuda_arch=89
xmake build -j12 peridyno  # PeriDyno：23 个 DLL + 75 个可执行文件
xmake f -y -c -m release --with_opencourant=y
xmake build -j12 opencourant # OpenCourant（仅 Windows x64 Release）
xmake run pbd_link_check   # 冒烟检查：PBD 库可链接可运行
xmake run mj_link_check    # 冒烟检查：mujoco.dll 可链接可运行
```

以上命令在仓库根目录运行，需要 Xmake 3.1 或更新版本。`-c` 重置配置选项，不会删除全部对象；`-a` 只构建当前已启用项目，不能代替 `--with_*=y`。

二进制、对象及依赖文件位于 `build/simulators/windows/x64/release/{bin,lib,obj,dep}`；生成头文件和 Fortran 模块也位于 `build/`。Python 绑定需使用 `--with_pypbd=y --pbd_python_root=...` 启用。第三方依赖源码位于根目录 `deps/`：缺失时使用脚本中的引导提交恢复，已有 checkout 按原样使用、不强制锁定或覆盖；更新上游时也应检查这些依赖及 OpenCourant 清单。Xmake 包未固定版本，也未启用包锁文件。

若出现 `oc-native-probe` 遮蔽根项目或 `project not found`，在根目录执行 `xmake f -P . -y -m release` 恢复项目关联，不必删除整个 `build/`。

OpenCourant 现使用原生 Fortran/C/C++ 对象目标、oneAPI 环境适配及必要的响应文件链接钩子；两组件构建已通过，但重构后的功能一致性、Fortran include/module 增量恢复和性能仍待验收。旧版本 miniQA 与耗时不代表新实现已验收。详细用法及限制见 [`xmake/README.md`](xmake/README.md)。

#### 一次性编译所有项目

在仓库根目录执行（Windows x64 Release）：

```powershell
# 首次配置：启用全部四个受管项目
xmake f -P . -y -c -m release --with_pbd=y --with_mujoco=y --with_peridyno=y --with_opencourant=y

# 一次性编译所有已启用目标；后续增量构建只需这一条
xmake build -a -j12

# 如需强制全量重编，使用此命令替代上一条
xmake build -a -r -j12
```

包含 PBD、MuJoCo、PeriDyno、OpenCourant，不包含 Python/Rust 项目。需要 MSVC、CUDA、Intel oneAPI/MKL，以及可用的 Python。`-a` 不会自动启用配置中关闭的项目。

如需 MuJoCo 测试，在配置命令末尾添加 `--with_mujoco_tests=y`；如需 PBD Python 绑定，添加 `--with_pypbd=y --pbd_python_root="你的Python安装目录"`。OpenCourant 重构版虽已构建通过，功能一致性与增量依赖正确性仍待验收。

## 设计原则

1. 通过 Git Submodule 隔离上游源码。
2. 通过固定 commit 保证仿真器版本可复现。
3. 以 Markdown 作为文档唯一事实来源。
4. 使用 Conda 为不同仿真器隔离 Python 环境。
5. Xmake 是仓库统一的编译入口：原生编译自编的编译型语言示例、实验以及仿真器库（构建描述放在 `xmake/simulators/` 下，引用只读上游源码）。
6. Example 用于学习单一能力，Experiment 用于回答技术问题。
7. Docs 与 Examples 使用仓库相对路径相互引用。
8. 在工具支持时，将生成内容集中到顶层 `build/`：官方仿真器使用 `build/simulators/<slug>/`，自编示例使用 `build/examples/`，文档站点使用 `build/docs/<slug>/`。
9. `.gitignore` 只对顶层 `/build/` 和不可避免的缓存、默认 `site/` 等产物做精确兜底，不使用 `**/build/` 隐藏任意位置的构建目录，使违反目录约定的产物能够被及时发现。
10. 官方仿真器的上游构建系统仍作为规范基线；仓库另外在 `xmake/simulators/` 下维护原生 Xmake 构建，编译同一份只读上游源码到 `build/simulators/`，且不改动上游源码树。

大型数据集、模型权重、大型网格、二进制文件、构建产物、视频、缓存和 Conda 环境本体不应提交到 Git。未来确有需求时再单独评估 Git LFS。

仓库规范见 [CONTRIBUTING.md](CONTRIBUTING.md)。
