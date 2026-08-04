#!/usr/bin/env python3
"""Batch 7: environments all variants (concise, standard, deepDive)"""
import re

BASE = "/Users/kartikjain/Desktop/code/learnflow/lib/sample_data"

def apply(filepath, replacements):
    with open(filepath, 'r') as f:
        content = f.read()
    applied = 0
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)
            applied += 1
        else:
            print(f"  MISS: {repr(old[:60])}")
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"  {filepath.split('/')[-1]}: {applied}/{len(replacements)}")
    return applied

# ============================================================
# lesson_environments.dart - CONCISE (c1-c5)
# ============================================================
env_c = [
    # c1
    ("""              'Environments and packaging, the short version. Every Python '
              'interpreter has one directory where installed packages live. '
              'Share that between projects and the first time two of them want '
              'different versions of the same library, you are stuck.'""",
     """              'Environments and packaging, the short version. Your Python installation has one global spot '
              'where all installed packages live — like one shared pantry for every recipe you ever cook. '
              'Share that pantry between projects and the moment one recipe needs salt v2 and another needs salt v1, '
              'dinner is ruined. This is the problem virtual environments solve.'"""),
    # c2
    ("""              'So: one virtual environment per project. python dash m venv dot '
              'venv creates it, source dot venv slash bin slash activate turns '
              'it on, and from then on pip installs into the project instead of '
              'into your operating system. Add dot venv to gitignore — it is '
              'build output, not source.'""",
     """              'The fix: one virtual environment per project, every time. python -m venv .venv creates it — '
              'it\\'s just a directory. source .venv/bin/activate turns it on — now pip installs go to your project, '
              'not your operating system. Add .venv to .gitignore — it\\'s build output, like compiled binaries, not source code. '
              'Anyone can recreate it from your dependency list.'"""),
    # c3
    ("""              'Always write python dash m pip rather than a bare pip. A bare '
              'pip is whichever one is first on your PATH, which may belong to '
              'a completely different interpreter. Invoking it as a module '
              'means the pip and the python can never disagree.'""",
     """              'Always write python -m pip, never bare pip. A bare pip could be any pip on your system — '
              'maybe from Python 3.9 when you\\'re running 3.12. Using python -m pip guarantees '
              'the pip you call matches the python you\\'re running. They can never disagree about where packages go, '
              'which prevents the maddening \"I installed it but Python can\\'t find it\" bug.'"""),
    # c4
    ("""              'What you commit is the dependency list. Applications pin exact '
              'versions so the thing you tested is the thing that runs. '
              'Libraries declare ranges instead, because a library that pins '
              'makes everyone downstream unable to resolve.'""",
     """              'What you actually commit to version control is the dependency list, not the packages themselves. '
              'Applications should pin exact versions in a lock file — the thing you tested is the thing that runs in production. '
              'Libraries should declare ranges instead (like \"requests >= 2.28, < 3\") because if a library pins exact versions, '
              'everyone downstream gets version conflicts they can\\'t resolve. Be a good citizen: apps pin, libraries don\\'t.'"""),
    # c5
    ("""              'And packaging is now one file. pyproject dot toml names the '
              'project, lists dependencies, picks a build backend and can '
              'declare console commands. Install your own project with pip '
              'install dash e dot while you work on it.'""",
     """              'And packaging your own project? It\\'s now one file: pyproject.toml. '
              'It names your project, lists dependencies, picks a build backend, and can even declare console commands — '
              'so typing \"my-tool\" in the terminal runs your Python function. '
              'Install your own project with pip install -e . in editable mode while you develop — '
              'changes to your source code show up immediately, no reinstall needed.'"""),
]
apply(f"{BASE}/python/lesson_environments.dart", env_c)

# ============================================================
# lesson_environments.dart - STANDARD (s1-s8)
# ============================================================
env_s = [
    # s1
    ("""              'Today: virtual environments and packaging. This is the part of '
              'Python that people find most confusing, and I think it is '
              'because it is usually taught as a list of commands to memorise '
              'rather than as one idea — which is that an environment is just a '
              'directory, and everything else follows from that.'""",
     """              'Today: virtual environments and packaging. This is the part of Python that confuses people the most, '
              'and I think it\\'s because it\\'s usually taught as a list of commands to memorize. '
              'But it all clicks when you realize one thing: an environment is just a directory. '
              'That\\'s it. A folder with a Python link, an empty packages folder, and a config file. '
              'Once you see that, everything else — activation, pip, requirements — makes sense.'"""),
    # s2
    ("""              'The starting problem is that installation is global per '
              'interpreter. There is one site-packages directory, and pip '
              'writes into it. So project A and project B share every library '
              'and every version. Upgrade a dependency for A and B changes '
              'underneath you, with no warning, because nothing recorded that B '
              'needed the old one.'""",
     """              'The core problem: Python installs packages globally per interpreter. One site-packages folder, '
              'and pip just dumps everything in there. So your two projects share every library and every version. '
              'Upgrade a library for project A, and project B silently breaks — maybe next week, maybe next deploy — '
              'because nothing recorded that B needed the old version. It\\'s like having one toolbox for every project '
              'in your life: update the hammer for your woodworking hobby and your picture-hanging project now has a different hammer.'"""),
    # s3
    ("""              'A virtual environment solves it by making a second, private '
              'site-packages. It is genuinely just a directory: a link to a '
              'Python interpreter, an empty site-packages, and a small config '
              'file. Create it with python dash m venv, and keep it inside the '
              'project so it is obvious which one it belongs to.'""",
     """              'A virtual environment solves this by creating a second, private site-packages for each project. '
              'It\\'s literally just a folder: a symlink to your Python interpreter, an empty site-packages directory, '
              'and a tiny pyvenv.cfg file. That\\'s the whole thing. python -m venv .venv creates it. '
              'Keep it inside your project folder — right next to your source code — '
              'so it\\'s obvious which environment belongs to which project. And don\\'t commit it!'"""),
    # s4
    ("""              'Activation is worth demystifying too. The activate script '
              'prepends the environment\\'s bin directory to PATH and sets a '
              'variable so your prompt can show it. That is all. You can skip '
              'it entirely by running dot venv slash bin slash python directly, '
              'which is exactly what editors and CI systems do.'""",
     """              'Activation deserves demystifying because it feels like magic but isn\\'t. '
              'The activate script does exactly two things: prepends .venv/bin to your PATH so commands use the venv\\'s Python, '
              'and sets an environment variable so your prompt can show \"(venv)\". That\\'s all. '
              'You can skip activation entirely by running .venv/bin/python directly — '
              'which is exactly what VS Code and CI systems do. Activate is convenience, not requirement.'"""),
    # s5
    ("""              'The real isolation lives in the interpreter. On startup Python '
              'looks for a pyvenv dot cfg file beside its executable, and if it '
              'finds one it sets sys dot prefix to that directory while keeping '
              'sys dot base underscore prefix pointing at the original install. '
              'Comparing those two is the reliable way to check, from code, '
              'whether you are in an environment.'""",
     """              'The real isolation happens inside the Python interpreter itself. At startup, Python checks: '
              '\"Is there a pyvenv.cfg file next to me?\" If yes, it sets sys.prefix to the venv directory '
              'while keeping sys.base_prefix pointing at the original Python installation. '
              'So all package resolution routes through the venv, but the standard library still comes from the base install. '
              'Comparing sys.prefix and sys.base_prefix is the reliable way to detect from code whether you\\'re in a venv.'"""),
    # s6
    ("""              'On dependencies, keep two ideas separate. Abstract dependencies '
              '— what your code needs, expressed as ranges — go in pyproject '
              'dot toml. Concrete dependencies — the exact versions of '
              'everything including transitive packages — go in a lock file or '
              'a pinned requirements file. Applications pin. Libraries do not, '
              'because their pins become everyone else\\'s conflicts.'""",
     """              'Keep two kinds of dependencies straight in your head. Abstract dependencies — '
              'what your code actually needs, expressed as version ranges — go in pyproject.toml. '
              'Concrete dependencies — the exact versions of everything, including transitive packages, '
              'locked down so your build is reproducible — go in a lock file or requirements.txt. '
              'Applications pin: \"I need exactly these versions to work.\" Libraries don\\'t: '
              '\"I need anything compatible in this range.\" A library that pins makes everyone downstream fight version conflicts.'"""),
    # s7
    ("""              'Packaging has become genuinely pleasant. One pyproject dot toml '
              'declares the build backend, the project metadata, the '
              'dependencies, optional extras like a dev group, and console '
              'scripts that map a command name to a function. Install your own '
              'project with dash e for editable mode while you develop, and '
              'python dash m build produces a wheel when you are ready to '
              'ship.'""",
     """              'Packaging your own Python project is now genuinely pleasant. One pyproject.toml file declares '
              'the build backend, project name and version, dependencies, optional extras (like a [dev] group for testing tools), '
              'and console scripts — mapping a terminal command like \"deploy\" to a Python function. '
              'pip install -e . gives you editable mode during development — edit source, changes appear immediately. '
              'python -m build produces distributable wheels when you\\'re ready to share. '
              'It went from \"Python packaging is terrible\" to \"one file and done.\"'"""),
    # s8
    ("""              'And when something is broken, delete the environment and rebuild '
              'it. It holds nothing that is not already recorded. If the '
              'problem survives a rebuild, your dependency list is wrong — '
              'which is useful information.'""",
     """              'And here\\'s your nuclear option when things break: delete the environment and rebuild it. '
              'A venv holds nothing that isn\\'t already recorded in your dependency files. '
              'rm -rf .venv, python -m venv .venv, pip install -e . — takes 30 seconds. '
              'If the problem survives a clean rebuild, you know it\\'s your dependency declarations, not environmental cruft. '
              'That alone is worth the price of admission: it turns mysterious problems into actionable information.'"""),
]
apply(f"{BASE}/python/lesson_environments.dart", env_s)
print("Environments standard DONE.")
