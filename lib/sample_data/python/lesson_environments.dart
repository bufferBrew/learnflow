import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/lesson.dart';
import '../../models/podcast.dart';
import '../../models/review.dart';
import '../../models/source.dart';

/// Module 3, lesson 1: isolating dependencies and shipping your own code.
const Lesson environmentsLesson = Lesson(
  id: 'py-virtual-environments-and-packaging',
  title: 'Virtual Environments & Packaging',
  description:
      'Why every project needs its own interpreter environment, and how to '
      'turn a folder of scripts into an installable package.',
  estimatedMinutes: 20,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  review: _review,
  sources: _sources,
);

const ReadContent _read = ReadContent(
  sections: [
    Section(
      id: 'why-isolate',
      heading: 'Why isolation is not optional',
      blocks: [
        ProseBlock(
          'Installing a package puts it in one shared directory, '
          'site-packages, belonging to one interpreter. Two projects on the '
          'same machine therefore share every dependency and every version. The '
          'moment one needs an older release of a library the other has moved '
          'past, you cannot satisfy both — and upgrading for one project '
          'silently breaks the other.',
        ),
        ProseBlock(
          'A virtual environment is a directory containing its own '
          'site-packages and its own interpreter link. Activating it puts that '
          'interpreter first on your PATH, so pip installs into the project '
          'rather than into the system. It costs one command per project and '
          'removes an entire category of "works on my machine".',
        ),
        ProseBlock(
          'It also protects the operating system. On macOS and most Linux '
          'distributions the system Python is a component of the OS, and '
          'package managers rely on the exact versions it ships. Installing '
          'into it with sudo can break system tooling in ways that are '
          'genuinely hard to unpick — which is why recent Pythons refuse the '
          'operation outright with an "externally managed environment" error.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
import sys
import site

# Where is this interpreter, and where do its packages live?
print(sys.executable)        # .../myproject/.venv/bin/python
print(sys.prefix)            # .../myproject/.venv
print(sys.base_prefix)       # /usr/local  - the interpreter it was built from
print(site.getsitepackages())

# Inside an active virtual environment these two differ; outside one they match.
in_venv = sys.prefix != sys.base_prefix
print("virtual environment active:", in_venv)
''',
          caption: 'sys.prefix is the honest answer to "which environment?"',
        ),
        CalloutBlock(
          type: CalloutType.warning,
          title: 'Never sudo pip install',
          text:
              'It writes into the interpreter your operating system depends on '
              'and can leave system tools unusable. If a tool needs to be '
              'available globally, install it with pipx, which gives each tool '
              'its own hidden environment.',
        ),
      ],
    ),
    Section(
      id: 'creating',
      heading: 'Creating and using an environment',
      blocks: [
        ProseBlock(
          'venv ships with Python, so there is nothing to install. Create the '
          'environment inside the project, conventionally in a directory called '
          '.venv, and add that directory to .gitignore — an environment is '
          'build output, not source. What you commit is the list of '
          'dependencies, not the packages themselves.',
        ),
        ProseBlock(
          'Activation is a convenience, not a requirement: it edits PATH for '
          'the current shell so that python and pip mean the ones in the '
          'environment. You can always skip it by invoking the environment\'s '
          'interpreter by path, which is what editors, CI jobs and cron entries '
          'usually do.',
        ),
        CodeBlock(
          language: 'bash',
          code: r'''
# Create one, in the project directory
python3 -m venv .venv

# Activate: macOS / Linux
source .venv/bin/activate

# Activate: Windows PowerShell
# .venv\Scripts\Activate.ps1

# Now python and pip are the project's own
python -m pip install --upgrade pip
python -m pip install requests

deactivate            # restores the previous PATH

# Or skip activation entirely and be explicit
./.venv/bin/python -m pip install requests
''',
          caption: 'One environment per project, ignored by version control.',
        ),
        CalloutBlock(
          type: CalloutType.tip,
          title: 'Say "python -m pip", not "pip"',
          text:
              'A bare pip is whichever pip is first on PATH, which may belong '
              'to a different interpreter entirely. python -m pip installs into '
              'the interpreter you just named, so the two can never disagree.',
        ),
      ],
    ),
    Section(
      id: 'dependencies',
      heading: 'Recording dependencies',
      blocks: [
        ProseBlock(
          'There are two different lists, and conflating them causes most '
          'dependency confusion. Abstract dependencies are what your code needs '
          'to work — "requests, at least version 2.31" — and they belong in '
          'pyproject.toml. Concrete dependencies are the exact versions of '
          'everything, including transitive packages, that a particular '
          'deployment was tested with; those belong in a lock file or a pinned '
          'requirements.txt.',
        ),
        ProseBlock(
          'Applications should pin, because reproducibility is the point: the '
          'thing you tested should be the thing that runs. Libraries should '
          'not, because pinning propagates into every project that installs '
          'them and quickly makes their constraints unsatisfiable. Specify a '
          'range you actually support and let the resolver do its job.',
        ),
        CodeBlock(
          language: 'bash',
          code: r'''
# Freeze exactly what is installed right now (an application)
python -m pip freeze > requirements.txt

# Recreate that environment elsewhere
python -m pip install -r requirements.txt

# What is installed, and what needs upgrading?
python -m pip list
python -m pip list --outdated
python -m pip show requests
''',
          caption: 'freeze captures the concrete set; pyproject declares intent.',
        ),
      ],
    ),
    Section(
      id: 'packaging',
      heading: 'From a folder of scripts to a package',
      blocks: [
        ProseBlock(
          'A directory containing an __init__.py is a package: it can be '
          'imported as a unit, and it gives your modules a namespace. Turning '
          'that into something installable takes one more file, pyproject.toml, '
          'which names the project, states its version and dependencies, and '
          'declares which build backend should turn the source into a wheel.',
        ),
        ProseBlock(
          'pyproject.toml replaced setup.py as the standard interface. The '
          '[build-system] table says who builds; the [project] table holds the '
          'metadata every tool reads. Console script entry points let you '
          'declare a command-line name that maps to a function — installing the '
          'package then puts that command on the user\'s PATH.',
        ),
        CodeBlock(
          language: 'toml',
          code: r'''
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "weatherkit"
version = "0.1.0"
description = "Fetch and summarise forecasts"
requires-python = ">=3.10"
dependencies = [
    "requests>=2.31",
    "rich>=13.0",
]

[project.optional-dependencies]
dev = ["pytest>=8.0", "ruff>=0.5"]

[project.scripts]
weatherkit = "weatherkit.cli:main"
''',
          caption: 'The whole packaging contract in one file.',
        ),
        CodeBlock(
          language: 'bash',
          code: r'''
# Install your own project into the environment, in editable mode:
# code changes take effect without reinstalling.
python -m pip install -e .

# With the optional dev extras
python -m pip install -e ".[dev]"

# Build distributable artefacts into dist/
python -m pip install build
python -m build          # produces a .whl and a .tar.gz
''',
          caption: 'Editable installs during development, wheels for release.',
        ),
        CollapsibleBlock(
          title: 'Under the hood: what activation actually does',
          children: [
            ProseBlock(
              'The activate script is not magic and it is not required. It '
              'saves your current PATH, prepends the environment\'s bin '
              'directory, sets VIRTUAL_ENV, and defines a deactivate function '
              'that puts everything back. That is the entire mechanism — which '
              'is why running the environment\'s interpreter by full path works '
              'identically without activating anything.',
            ),
            ProseBlock(
              'The isolation itself comes from the interpreter, not the shell. '
              'When Python starts it looks for a pyvenv.cfg file next to its '
              'executable; finding one sets sys.prefix to that directory and '
              'therefore points site-packages at the environment, while '
              'sys.base_prefix keeps pointing at the original installation so '
              'the standard library is still found. Comparing those two values '
              'is the reliable way to detect an active environment in code.',
            ),
            CodeBlock(
              language: 'bash',
              code: r'''
cat .venv/pyvenv.cfg
# home = /usr/local/bin
# include-system-site-packages = false
# version = 3.12.4

# The environment is disposable: never fix it, just rebuild it.
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
''',
            ),
          ],
        ),
      ],
    ),
    Section(
      id: 'tooling',
      heading: 'Where the ecosystem is going',
      blocks: [
        ProseBlock(
          'venv plus pip is the standard baseline and always available, but a '
          'generation of tools now wraps the same primitives with a lock file '
          'and a single command: uv, Poetry, PDM and Hatch all create the '
          'environment, resolve dependencies, record exact versions and run '
          'your code. They differ in speed and philosophy, not in the '
          'underlying standards — every one of them produces a normal wheel '
          'from a normal pyproject.toml.',
        ),
        ProseBlock(
          'Learn the primitives first anyway. When a tool misbehaves, the '
          'question you will need to answer is which interpreter is running and '
          'which site-packages it can see, and that is answered by sys.executable '
          'and sys.prefix regardless of what created the environment.',
        ),
        CodeBlock(
          language: 'python',
          code: '''
from importlib.metadata import version, distributions, PackageNotFoundError

# Ask the environment what it actually has, from inside the program.
try:
    print("requests", version("requests"))
except PackageNotFoundError:
    print("requests is not installed in this environment")

installed = sorted(d.metadata["Name"] for d in distributions())
print(len(installed), "distributions:", installed[:5])
''',
          caption:
              'importlib.metadata reads installed package metadata at runtime.',
        ),
      ],
    ),
  ],
);

const PracticeContent _practice = PracticeContent(
  exercises: [
    Exercise(
      id: 'ex-env-detect',
      title: 'Detect the environment you are running in',
      prompt: [
        ProseBlock(
          'Write environment_report() that returns a dict describing the '
          'running interpreter: its executable path, its version as a string '
          'like "3.12.4", whether a virtual environment is active, and the '
          'prefix directory. Detect the environment by comparing sys.prefix '
          'with sys.base_prefix — do not look at the VIRTUAL_ENV variable, '
          'which is only set when a shell activated it.',
        ),
      ],
      starterCode: '''
import sys


def environment_report():
    # TODO: return {"executable", "version", "in_venv", "prefix"}
    ...


for key, value in environment_report().items():
    print(f"{key}: {value}")
''',
      solutionCode: '''
import sys


def environment_report():
    return {
        "executable": sys.executable,
        "version": ".".join(str(part) for part in sys.version_info[:3]),
        "in_venv": sys.prefix != sys.base_prefix,
        "prefix": sys.prefix,
    }


for key, value in environment_report().items():
    print(f"{key}: {value}")
# executable: /path/to/project/.venv/bin/python
# version: 3.12.4
# in_venv: True
# prefix: /path/to/project/.venv
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why is comparing sys.prefix with sys.base_prefix more reliable '
              'than checking the VIRTUAL_ENV environment variable?',
          expectedAnswer:
              'VIRTUAL_ENV is set by the activate script, so it is absent when '
              'the environment\'s interpreter is invoked directly by path — as '
              'editors, CI jobs and cron do — and it can be stale if it was '
              'exported and the shell later moved on. The prefix comparison '
              'asks the running interpreter itself, which cannot be wrong.',
        ),
        SelfCheckQuestion(
          question:
              'Two projects both depend on requests. What actually stops them '
              'sharing one copy?',
          expectedAnswer:
              'Nothing about the package: it is about where site-packages '
              'lives. Each environment has its own site-packages under its own '
              'sys.prefix, so each holds an independent copy of requests at '
              'whichever version that project pinned. Disk cost is the price of '
              'not having a single global version everyone must agree on.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-env-pyproject',
      title: 'Write a minimal pyproject.toml',
      prompt: [
        ProseBlock(
          'You have a package directory called textkit containing __init__.py '
          'and cli.py, and cli.py defines main(). Write the pyproject.toml that '
          'makes this installable: declare the hatchling build backend, name '
          'and version the project, require Python 3.10 or newer, depend on '
          'rich 13 or newer, add pytest as a dev extra, and expose a console '
          'command named textkit that calls main().',
        ),
      ],
      starterCode: r'''
[build-system]
# TODO: requires and build-backend

[project]
name = "textkit"
# TODO: version, requires-python, dependencies

# TODO: [project.optional-dependencies] with a dev extra
# TODO: [project.scripts] mapping textkit -> textkit.cli:main
''',
      solutionCode: r'''
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "textkit"
version = "0.1.0"
description = "Small text utilities"
requires-python = ">=3.10"
dependencies = ["rich>=13.0"]

[project.optional-dependencies]
dev = ["pytest>=8.0"]

[project.scripts]
textkit = "textkit.cli:main"

# Then, from the project root, inside an activated environment:
#   python -m pip install -e ".[dev]"
#   textkit --help
''',
      language: 'toml',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'What does the -e flag change about the install, and why use it '
              'while developing?',
          expectedAnswer:
              'An editable install puts a link to your source tree on the '
              'import path instead of copying files into site-packages, so '
              'every edit takes effect on the next run with no reinstall. It '
              'also means you are importing the package exactly as a user '
              'would, through its declared name, which catches missing modules '
              'and bad relative imports that running scripts from the source '
              'directory would hide.',
        ),
        SelfCheckQuestion(
          question:
              'Why put pytest under optional-dependencies rather than in '
              'dependencies?',
          expectedAnswer:
              'Because a user installing your package to use it should not be '
              'made to download your test framework. Extras are opt-in: '
              'contributors install the dev group explicitly, while a normal '
              'install pulls only what the code needs at runtime.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-env-recreate',
      title: 'Recreate an environment from scratch',
      prompt: [
        ProseBlock(
          'A colleague reports that the project runs on their machine but not '
          'on yours, with an ImportError. Write the sequence of commands that '
          'discards your environment entirely, builds a fresh one, installs the '
          'recorded dependencies plus the project itself in editable mode, and '
          'verifies which interpreter is in use. Then say why deleting is '
          'preferable to repairing.',
        ),
      ],
      starterCode: r'''
# TODO: remove the old environment
# TODO: create and activate a new one
# TODO: upgrade pip, install requirements.txt, install the project editable
# TODO: verify the interpreter and the installed package list
''',
      solutionCode: r'''
# 1. The environment is build output. Throw it away.
rm -rf .venv

# 2. Rebuild and activate.
python3 -m venv .venv
source .venv/bin/activate

# 3. Install exactly what is recorded, then the project itself.
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pip install -e .

# 4. Verify you are using the environment you think you are.
python -c "import sys; print(sys.executable, sys.prefix != sys.base_prefix)"
python -m pip list
''',
      language: 'bash',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why delete the environment rather than trying to fix it?',
          expectedAnswer:
              'Because it contains no information that is not already in '
              'requirements.txt and pyproject.toml — it is a derived artefact. '
              'Rebuilding takes seconds and proves the recorded dependency list '
              'is complete, whereas repairing hides the fact that the list was '
              'wrong and leaves the machine in a state nobody can reproduce.',
        ),
        SelfCheckQuestion(
          question:
              'The ImportError persists after the rebuild. What does that tell '
              'you?',
          expectedAnswer:
              'That the dependency is missing from the recorded list rather '
              'than from the machine — it was probably installed ad hoc on the '
              'colleague\'s machine and never added to requirements.txt or '
              'pyproject.toml. The fix belongs in the dependency declaration, '
              'not in another manual pip install.',
        ),
      ],
    ),
  ],
);

const PodcastScript _podcast = PodcastScript(
  variants: {
    PodcastVariant.concise: ScriptVariant(
      variant: PodcastVariant.concise,
      totalDurationMs: 204000,
      segments: [
        PodcastSegment(
          id: 'c1',
          speaker: 'Host',
          text:
              'Environments and packaging, the short version. Every Python '
              'interpreter has one directory where installed packages live. '
              'Share that between projects and the first time two of them want '
              'different versions of the same library, you are stuck.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'So: one virtual environment per project. python dash m venv dot '
              'venv creates it, source dot venv slash bin slash activate turns '
              'it on, and from then on pip installs into the project instead of '
              'into your operating system. Add dot venv to gitignore — it is '
              'build output, not source.',
          startMs: 42000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Always write python dash m pip rather than a bare pip. A bare '
              'pip is whichever one is first on your PATH, which may belong to '
              'a completely different interpreter. Invoking it as a module '
              'means the pip and the python can never disagree.',
          startMs: 92000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'What you commit is the dependency list. Applications pin exact '
              'versions so the thing you tested is the thing that runs. '
              'Libraries declare ranges instead, because a library that pins '
              'makes everyone downstream unable to resolve.',
          startMs: 134000,
          endMs: 174000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And packaging is now one file. pyproject dot toml names the '
              'project, lists dependencies, picks a build backend and can '
              'declare console commands. Install your own project with pip '
              'install dash e dot while you work on it.',
          startMs: 174000,
          endMs: 204000,
        ),
      ],
    ),
    PodcastVariant.standard: ScriptVariant(
      variant: PodcastVariant.standard,
      totalDurationMs: 474000,
      segments: [
        PodcastSegment(
          id: 's1',
          speaker: 'Host',
          text:
              'Today: virtual environments and packaging. This is the part of '
              'Python that people find most confusing, and I think it is '
              'because it is usually taught as a list of commands to memorise '
              'rather than as one idea — which is that an environment is just a '
              'directory, and everything else follows from that.',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The starting problem is that installation is global per '
              'interpreter. There is one site-packages directory, and pip '
              'writes into it. So project A and project B share every library '
              'and every version. Upgrade a dependency for A and B changes '
              'underneath you, with no warning, because nothing recorded that B '
              'needed the old one.',
          startMs: 52000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'A virtual environment solves it by making a second, private '
              'site-packages. It is genuinely just a directory: a link to a '
              'Python interpreter, an empty site-packages, and a small config '
              'file. Create it with python dash m venv, and keep it inside the '
              'project so it is obvious which one it belongs to.',
          startMs: 122000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Activation is worth demystifying too. The activate script '
              'prepends the environment\'s bin directory to PATH and sets a '
              'variable so your prompt can show it. That is all. You can skip '
              'it entirely by running dot venv slash bin slash python directly, '
              'which is exactly what editors and CI systems do.',
          startMs: 186000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'The real isolation lives in the interpreter. On startup Python '
              'looks for a pyvenv dot cfg file beside its executable, and if it '
              'finds one it sets sys dot prefix to that directory while keeping '
              'sys dot base underscore prefix pointing at the original install. '
              'Comparing those two is the reliable way to check, from code, '
              'whether you are in an environment.',
          startMs: 248000,
          endMs: 316000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'On dependencies, keep two ideas separate. Abstract dependencies '
              '— what your code needs, expressed as ranges — go in pyproject '
              'dot toml. Concrete dependencies — the exact versions of '
              'everything including transitive packages — go in a lock file or '
              'a pinned requirements file. Applications pin. Libraries do not, '
              'because their pins become everyone else\'s conflicts.',
          startMs: 316000,
          endMs: 392000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Packaging has become genuinely pleasant. One pyproject dot toml '
              'declares the build backend, the project metadata, the '
              'dependencies, optional extras like a dev group, and console '
              'scripts that map a command name to a function. Install your own '
              'project with dash e for editable mode while you develop, and '
              'python dash m build produces a wheel when you are ready to '
              'ship.',
          startMs: 392000,
          endMs: 452000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And when something is broken, delete the environment and rebuild '
              'it. It holds nothing that is not already recorded. If the '
              'problem survives a rebuild, your dependency list is wrong — '
              'which is useful information.',
          startMs: 452000,
          endMs: 474000,
        ),
      ],
    ),
    PodcastVariant.deepDive: ScriptVariant(
      variant: PodcastVariant.deepDive,
      totalDurationMs: 810000,
      segments: [
        PodcastSegment(
          id: 'd1',
          speaker: 'Host',
          text:
              'The long version on environments and distribution. We will trace '
              'how an import actually finds a module, what a virtual '
              'environment changes about that, how wheels differ from source '
              'distributions, what the build backend interface is, and how the '
              'modern tools fit on top of the same standards.',
          startMs: 0,
          endMs: 64000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Start with import. When you import a name, Python walks sys dot '
              'path in order — the script\'s directory, then anything in '
              'PYTHONPATH, then the standard library, then site-packages. The '
              'first match wins. That single ordering explains an enormous '
              'number of mysteries, including the classic one where a file '
              'called random dot py in your project shadows the standard '
              'library module of the same name.',
          startMs: 64000,
          endMs: 152000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'A virtual environment changes exactly one thing about that: '
              'which site-packages ends up on the path. The pyvenv dot cfg file '
              'sets sys dot prefix, the site module computes site-packages from '
              'the prefix, and the standard library still comes from the base '
              'installation. So an environment is not a copy of Python — it is '
              'a redirect, which is why creating one is instantaneous.',
          startMs: 152000,
          endMs: 236000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'There is a flag in that config worth knowing: '
              'include-system-site-packages. Set it true and the environment '
              'can see the base installation\'s packages as well. It is '
              'occasionally useful for heavyweight system-installed libraries, '
              'and it is usually a mistake, because it reintroduces the '
              'invisible coupling you created the environment to escape.',
          startMs: 236000,
          endMs: 310000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now distribution formats. A source distribution — an sdist — is '
              'a tarball of your source that has to be built on the target '
              'machine. A wheel is a zip of the already-built package with a '
              'standard name encoding the Python version, ABI and platform it '
              'targets. Installing a wheel is essentially unzip and copy, which '
              'is why it is fast and why it does not need a compiler on the '
              'user\'s machine.',
          startMs: 310000,
          endMs: 398000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Pure-Python packages produce one universal wheel. Anything with '
              'C extensions needs a wheel per platform, which is what the '
              'manylinux standard exists to define — a baseline of system '
              'libraries a Linux wheel may rely on. When pip says it is '
              '"building wheel for something" and then fails on a missing '
              'header, that is the moment you learn no matching wheel was '
              'published for your platform.',
          startMs: 398000,
          endMs: 482000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The build backend interface is the other standard worth knowing. '
              'pyproject dot toml declares which backend to use, pip installs '
              'that backend into an isolated build environment, then calls '
              'well-defined hooks on it to produce the wheel. That is why '
              'setuptools, hatchling, flit and poetry-core are '
              'interchangeable from the installer\'s point of view — they all '
              'implement the same interface.',
          startMs: 482000,
          endMs: 566000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Version specifiers deserve precision as well. Double-equals pins '
              'exactly. Greater-than-or-equal sets a floor. The tilde-equals '
              'operator is compatible-release — tilde equals one point four '
              'point two allows one point four point anything but not one point '
              'five. For libraries, set a floor at the oldest version you '
              'actually test, and add an upper bound only when you know a '
              'future major release will break you.',
          startMs: 566000,
          endMs: 652000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'On the tooling layer: uv, Poetry, PDM and Hatch each add a '
              'resolver with a lock file, project scaffolding and a run command. '
              'uv is dramatically faster because it is written in Rust and '
              'caches aggressively. But all of them produce ordinary wheels '
              'from ordinary pyproject files, so the choice is about workflow '
              'ergonomics and not about lock-in.',
          startMs: 652000,
          endMs: 728000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two practices to end on. Use pipx for command-line tools you '
              'want globally — it gives each tool its own hidden environment, '
              'so installing two tools with conflicting dependencies just '
              'works. And never sudo pip install: the system interpreter '
              'belongs to your operating system, and recent Pythons will refuse '
              'you anyway with an externally-managed-environment error.',
          startMs: 728000,
          endMs: 810000,
        ),
      ],
    ),
  },
);

const ReviewContent _review = ReviewContent(
  summaryCards: [
    SummaryCard(
      title: 'One environment per project',
      body:
          'Package installation is global per interpreter, so projects sharing '
          'one interpreter share every version. python -m venv .venv gives a '
          'project its own site-packages. The directory is build output — '
          'gitignore it, and rebuild rather than repair.',
    ),
    SummaryCard(
      title: 'Abstract versus concrete dependencies',
      body:
          'pyproject.toml declares what your code needs as ranges; a lock file '
          'or pinned requirements.txt records the exact versions a deployment '
          'was tested with. Applications pin; libraries declare ranges so '
          'downstream resolution stays possible.',
    ),
    SummaryCard(
      title: 'pyproject.toml is the whole contract',
      body:
          'It names the build backend, the project metadata, dependencies, '
          'optional extras and console scripts. pip install -e . during '
          'development, python -m build to produce a wheel for release.',
    ),
  ],
  keyConcepts: [
    KeyConcept(
      term: 'site-packages',
      definition:
          'The directory an interpreter installs third-party packages into and '
          'searches on import. Each virtual environment has its own, which is '
          'the entire basis of isolation.',
    ),
    KeyConcept(
      term: 'sys.prefix vs sys.base_prefix',
      definition:
          'The active environment\'s root versus the interpreter installation '
          'it was created from. They differ exactly when a virtual environment '
          'is in use, which is the reliable way to detect one.',
    ),
    KeyConcept(
      term: 'Editable install',
      definition:
          'pip install -e . puts a link to your source tree on the import path '
          'instead of copying it, so edits take effect immediately while the '
          'package is still imported by its real name.',
    ),
    KeyConcept(
      term: 'Wheel',
      definition:
          'A built distribution: a zip archive installed by unpacking, with a '
          'filename encoding the Python version, ABI and platform it targets. '
          'Faster than a source distribution and needs no compiler.',
    ),
    KeyConcept(
      term: 'Build backend',
      definition:
          'The tool named in [build-system] — hatchling, setuptools, flit, '
          'poetry-core — that pip installs in isolation and calls through '
          'standard hooks to turn your source into a wheel.',
    ),
    KeyConcept(
      term: 'Pinning',
      definition:
          'Recording exact versions (==) so an install is reproducible. Correct '
          'for applications and harmful in libraries, where pins become '
          'unsatisfiable constraints for every downstream project.',
    ),
  ],
  mistakes: [
    Mistake(
      mistake: 'Running sudo pip install to fix a permissions error.',
      correction:
          'That writes into the interpreter your OS depends on and can break '
          'system tooling. Create a virtual environment for project work, or '
          'use pipx for globally available command-line tools.',
    ),
    Mistake(
      mistake: 'Committing the .venv directory, or pip freeze output for a library.',
      correction:
          'The environment is derived output — gitignore it and commit the '
          'dependency declaration instead. And freeze pins transitive versions, '
          'which makes a library impossible for downstream projects to resolve; '
          'declare ranges in pyproject.toml.',
    ),
    Mistake(
      mistake:
          'Using a bare "pip install" and wondering why the import still '
          'fails.',
      correction:
          'The pip first on PATH may belong to a different interpreter. Use '
          '"python -m pip install" so the package lands in the interpreter you '
          'are about to run, and check sys.executable when in doubt.',
    ),
  ],
  interviewQuestions: [
    InterviewQuestion(
      question: 'What does a virtual environment actually do?',
      answer:
          'It creates a directory containing a link to an interpreter, an empty '
          'site-packages and a pyvenv.cfg file. When that interpreter starts it '
          'sees the config file and sets sys.prefix to the environment, so '
          'site-packages resolves there while the standard library still comes '
          'from the base installation recorded in sys.base_prefix. Activation '
          'is only a PATH convenience — running the environment\'s interpreter '
          'by full path is equivalent.',
    ),
    InterviewQuestion(
      question:
          'When should you pin exact dependency versions and when should you '
          'not?',
      answer:
          'Pin for applications and deployed services, where the goal is that '
          'the artefact you tested is the artefact that runs; a lock file '
          'capturing transitive versions is the right form. Do not pin in a '
          'library: its constraints are combined with every other package in '
          'the user\'s environment, and exact pins quickly make resolution '
          'impossible. A library should state the minimum version it supports '
          'and add an upper bound only for a known incompatibility.',
    ),
    InterviewQuestion(
      question: 'What is the difference between a wheel and an sdist?',
      answer:
          'An sdist is a source tarball that must be built on the target '
          'machine, which requires the build backend and, for C extensions, a '
          'compiler and headers. A wheel is a pre-built zip that installs by '
          'unpacking, with a filename encoding the Python version, ABI and '
          'platform it supports. Pure-Python projects publish one universal '
          'wheel; compiled projects publish one per platform, which is what the '
          'manylinux tags exist to standardise.',
    ),
  ],
);

const List<Source> _sources = [
  Source(
    title: '12. Virtual Environments and Packages — Python Docs',
    url: 'https://docs.python.org/3/tutorial/venv.html',
    description:
        'Tutorial chapter on creating and activating environments and managing '
        'packages with pip and requirements files.',
  ),
  Source(
    title: 'venv — Python Docs',
    url: 'https://docs.python.org/3/library/venv.html',
    description:
        'Module reference covering the directory layout an environment '
        'creates, the contents of pyvenv.cfg and how the interpreter uses it.',
  ),
];
