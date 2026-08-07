import '../../models/content_block.dart';
import '../../models/exercise.dart';
import '../../models/game.dart';
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
  estimatedMinutes: 28,
  read: _read,
  practice: _practice,
  podcast: _podcast,
  play: _play,
  review: _review,
  sources: _sources,
  furtherReading: _furtherReading,
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
        ProseBlock(
          'include-system-site-packages in pyvenv.cfg is a flag that lets '
          'your environment see packages installed globally. It sounds '
          'convenient ("I already have NumPy installed globally") but it '
          'reintroduces invisible coupling — your project now silently depends '
          'on whatever version happens to be on the system. Leave it false '
          'unless you have a specific, documented reason.',
        ),
        CodeBlock(
          language: 'bash',
          code: r'''
# DO NOT do this without a good reason:
# python3 -m venv --system-site-packages .venv

# The right way: isolation. If you need a global tool, use pipx:
# pipx install black
# pipx install ruff
''',
          caption: 'System site-packages breaks isolation; use pipx for global tools.',
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
        ProseBlock(
          'pipx is the companion tool for globally available command-line '
          'tools. Each tool gets its own isolated environment, so two tools '
          'with incompatible dependencies coexist without conflict. Use pipx '
          'for black, ruff, httpie, and any Python-based CLI you want '
          'available everywhere without polluting your project environments.',
        ),
        CodeBlock(
          language: 'bash',
          code: r'''
# Install CLI tools globally, in their own isolated environments.
pipx install black
pipx install ruff
pipx install httpie

# Run a tool once without installing it permanently.
pipx run pycowsay "hello"

# List everything pipx manages.
pipx list
''',
          caption: 'pipx isolates CLI tools; each gets its own hidden venv.',
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
    Exercise(
      id: 'ex-env-importlib',
      title: 'Read installed package metadata programmatically',
      prompt: [
        ProseBlock(
          'Write list_dependencies() that uses importlib.metadata to return a '
          'dict mapping every installed distribution name to its version. '
          'Exclude any package whose name starts with an underscore (private '
          'convention) and sort the result alphabetically by name. Do not '
          'shell out to pip.',
        ),
      ],
      starterCode: '''
from importlib.metadata import distributions


def list_dependencies():
    # TODO: iterate distributions(), build {name: version} dict, exclude _
    ...


for name, ver in list_dependencies().items():
    print(f"{name}=={ver}")
''',
      solutionCode: '''
from importlib.metadata import distributions


def list_dependencies():
    result = {}
    for dist in distributions():
        name = dist.metadata["Name"]
        if name.startswith("_"):
            continue
        result[name] = dist.version
    return dict(sorted(result.items()))


for name, ver in list_dependencies().items():
    print(f"{name}=={ver}")
# Output varies by environment — shows every package pip or
# the build backend installed, alphabetically.
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why use importlib.metadata instead of parsing pip freeze output?',
          expectedAnswer:
              'importlib.metadata reads the same metadata pip write '
              'directly from the installed package directories. It works '
              'regardless of whether pip is available, runs orders of '
              'magnitude faster than a subprocess, and cannot be confused by '
              'pip version differences or shell escaping issues.',
        ),
        SelfCheckQuestion(
          question:
              'What kind of packages start with an underscore, and why '
              'exclude them?',
          expectedAnswer:
              'Build backends and tools sometimes install private helper '
              'packages with underscore-prefixed names (e.g. _virtualenv). '
              'These are implementation details, not user-facing dependencies, '
              'and listing them adds noise without useful information.',
        ),
      ],
    ),
    Exercise(
      id: 'ex-env-version-compare',
      title: 'Check if a minimum version is satisfied',
      prompt: [
        ProseBlock(
          'Write check_minimum_version(package, minimum) that uses '
          'importlib.metadata.version to get the installed version and '
          'packaging.version.parse to compare it against the minimum. Return '
          'True if the installed version is at least the minimum, False if the '
          'package is not installed, and raise if the version strings cannot '
          'be parsed.',
        ),
      ],
      starterCode: '''
from importlib.metadata import version, PackageNotFoundError
from packaging.version import parse as parse_version


def check_minimum_version(package, minimum):
    # TODO: get installed version, compare with minimum using parse_version
    ...


print(check_minimum_version("pip", "20.0"))    # True (pip is installed)
print(check_minimum_version("nonexistent", "1.0"))   # False
''',
      solutionCode: '''
from importlib.metadata import version, PackageNotFoundError
from packaging.version import parse as parse_version


def check_minimum_version(package, minimum):
    try:
        installed = version(package)
    except PackageNotFoundError:
        return False
    return parse_version(installed) >= parse_version(minimum)


print(check_minimum_version("pip", "20.0"))
# True (pip is almost certainly >= 20.0)

print(check_minimum_version("nonexistent", "1.0"))
# False

print(check_minimum_version("pip", "999.0"))
# False — pip will never satisfy this
''',
      language: 'python',
      selfChecks: [
        SelfCheckQuestion(
          question:
              'Why use packaging.version.parse rather than a plain string '
              'comparison or tuple of ints?',
          expectedAnswer:
              'Version numbers can include pre-release markers ("1.0a1"), '
              'post-release ("1.0.post1"), epochs ("1!2.0"), and local '
              'identifiers ("1.0+ubuntu"). parse_version handles all of these '
              'correctly according to PEP 440; string comparison or manual '
              'splitting on dots gets them wrong in subtle ways.',
        ),
        SelfCheckQuestion(
          question: 'Where does packaging.version come from?',
          expectedAnswer:
              'The packaging library (install with pip install packaging). '
              'It is a dependency of pip itself, so it is usually already '
              'present in any environment that has pip. It is the reference '
              'implementation of PEP 440 version parsing.',
        ),
      ],
    ),
  ],
);

const GameContent _play = GameContent(
  games: [
    FillBlankGame(
      id: 'game-environments-venv-command',
      title: 'Create the environment',
      instructions: 'Type the missing module name.',
      code: '''
python3 -m ______ .venv
source .venv/bin/activate
''',
      blanks: [Blank(answer: 'venv', hint: 'standard library module')],
    ),
    BugHuntGame(
      id: 'game-environments-sudo-pip',
      title: 'Find the risky install',
      instructions: 'Tap the line that can break the system Python.',
      code: '''
python3 -m venv .venv
source .venv/bin/activate
sudo pip install requests
python -m pip list
''',
      buggyLine: 3,
      explanation:
          'sudo pip install writes into the interpreter the operating '
          'system depends on, and can break system tooling. Install into '
          'the already-activated project environment, without sudo.',
      fixedCode: '''
python3 -m venv .venv
source .venv/bin/activate
python -m pip install requests
python -m pip list
''',
    ),
    OutputPredictorGame(
      id: 'game-environments-prefix-check',
      title: 'What does this print?',
      instructions: 'Assume the interpreter is NOT inside a virtual environment.',
      code: '''
import sys

in_venv = sys.prefix != sys.base_prefix
print(in_venv)
''',
      options: ['True', 'False', 'AttributeError', 'None'],
      correctIndex: 1,
      explanation:
          'Outside an active virtual environment, sys.prefix and '
          'sys.base_prefix point at the same installation, so the '
          'comparison is False. They differ only while a venv is active.',
    ),
    TermMatchGame(
      id: 'game-environments-terms',
      title: 'Match the vocabulary',
      instructions: 'Tap a term, then tap its definition.',
      pairs: [
        TermPair(
          term: 'site-packages',
          definition: 'Where an interpreter installs and searches for packages.',
        ),
        TermPair(
          term: 'sys.prefix vs sys.base_prefix',
          definition: 'The active environment\'s root versus the base interpreter.',
        ),
        TermPair(
          term: 'Editable install',
          definition: 'Links your source tree onto the import path instead of copying it.',
        ),
        TermPair(
          term: 'Wheel',
          definition: 'A built distribution, installed by unpacking rather than compiling.',
        ),
        TermPair(
          term: 'Pinning',
          definition: 'Recording exact versions so an install is reproducible.',
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
              'Environments and packaging, the short version. Your Python installation has one global spot '
              'where all installed packages live — like one shared pantry for every recipe you ever cook. '
              'Share that pantry between projects and the moment one recipe needs salt v2 and another needs salt v1, '
              'dinner is ruined. This is the problem virtual environments solve.',
          startMs: 0,
          endMs: 42000,
        ),
        PodcastSegment(
          id: 'c2',
          speaker: 'Guest',
          text:
              'The fix: one virtual environment per project, every time. python -m venv .venv creates it — '
              'it\'s just a directory. source .venv/bin/activate turns it on — now pip installs go to your project, '
              'not your operating system. Add .venv to .gitignore — it\'s build output, like compiled binaries, not source code. '
              'Anyone can recreate it from your dependency list.',
          startMs: 42000,
          endMs: 92000,
        ),
        PodcastSegment(
          id: 'c3',
          speaker: 'Host',
          text:
              'Always write python -m pip, never bare pip. A bare pip could be any pip on your system — '
              'maybe from Python 3.9 when you\'re running 3.12. Using python -m pip guarantees '
              'the pip you call matches the python you\'re running. They can never disagree about where packages go, '
              'which prevents the maddening "I installed it but Python can\'t find it" bug.',
          startMs: 92000,
          endMs: 134000,
        ),
        PodcastSegment(
          id: 'c4',
          speaker: 'Guest',
          text:
              'What you actually commit to version control is the dependency list, not the packages themselves. '
              'Applications should pin exact versions in a lock file — the thing you tested is the thing that runs in production. '
              'Libraries should declare ranges instead (like "requests >= 2.28, < 3") because if a library pins exact versions, '
              'everyone downstream gets version conflicts they can\'t resolve. Be a good citizen: apps pin, libraries don\'t.',
          startMs: 134000,
          endMs: 174000,
        ),
        PodcastSegment(
          id: 'c5',
          speaker: 'Host',
          text:
              'And packaging your own project? It\'s now one file: pyproject.toml. '
              'It names your project, lists dependencies, picks a build backend, and can even declare console commands — '
              'so typing "my-tool" in the terminal runs your Python function. '
              'Install your own project with pip install -e . in editable mode while you develop — '
              'changes to your source code show up immediately, no reinstall needed.',
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
              'Today: virtual environments and packaging. This is the part of Python that confuses people the most, '
              'and I think it\'s because it\'s usually taught as a list of commands to memorize. '
              'But it all clicks when you realize one thing: an environment is just a directory. '
              'That\'s it. A folder with a Python link, an empty packages folder, and a config file. '
              'Once you see that, everything else — activation, pip, requirements — makes sense.',
          startMs: 0,
          endMs: 52000,
        ),
        PodcastSegment(
          id: 's2',
          speaker: 'Guest',
          text:
              'The core problem: Python installs packages globally per interpreter. One site-packages folder, '
              'and pip just dumps everything in there. So your two projects share every library and every version. '
              'Upgrade a library for project A, and project B silently breaks — maybe next week, maybe next deploy — '
              'because nothing recorded that B needed the old version. It\'s like having one toolbox for every project '
              'in your life: update the hammer for your woodworking hobby and your picture-hanging project now has a different hammer.',
          startMs: 52000,
          endMs: 122000,
        ),
        PodcastSegment(
          id: 's3',
          speaker: 'Host',
          text:
              'A virtual environment solves this by creating a second, private site-packages for each project. '
              'It\'s literally just a folder: a symlink to your Python interpreter, an empty site-packages directory, '
              'and a tiny pyvenv.cfg file. That\'s the whole thing. python -m venv .venv creates it. '
              'Keep it inside your project folder — right next to your source code — '
              'so it\'s obvious which environment belongs to which project. And don\'t commit it!',
          startMs: 122000,
          endMs: 186000,
        ),
        PodcastSegment(
          id: 's4',
          speaker: 'Guest',
          text:
              'Activation deserves demystifying because it feels like magic but isn\'t. '
              'The activate script does exactly two things: prepends .venv/bin to your PATH so commands use the venv\'s Python, '
              'and sets an environment variable so your prompt can show "(venv)". That\'s all. '
              'You can skip activation entirely by running .venv/bin/python directly — '
              'which is exactly what VS Code and CI systems do. Activate is convenience, not requirement.',
          startMs: 186000,
          endMs: 248000,
        ),
        PodcastSegment(
          id: 's5',
          speaker: 'Host',
          text:
              'The real isolation happens inside the Python interpreter itself. At startup, Python checks: '
              '"Is there a pyvenv.cfg file next to me?" If yes, it sets sys.prefix to the venv directory '
              'while keeping sys.base_prefix pointing at the original Python installation. '
              'So all package resolution routes through the venv, but the standard library still comes from the base install. '
              'Comparing sys.prefix and sys.base_prefix is the reliable way to detect from code whether you\'re in a venv.',
          startMs: 248000,
          endMs: 316000,
        ),
        PodcastSegment(
          id: 's6',
          speaker: 'Guest',
          text:
              'Keep two kinds of dependencies straight in your head. Abstract dependencies — '
              'what your code actually needs, expressed as version ranges — go in pyproject.toml. '
              'Concrete dependencies — the exact versions of everything, including transitive packages, '
              'locked down so your build is reproducible — go in a lock file or requirements.txt. '
              'Applications pin: "I need exactly these versions to work." Libraries don\'t: '
              '"I need anything compatible in this range." A library that pins makes everyone downstream fight version conflicts.',
          startMs: 316000,
          endMs: 392000,
        ),
        PodcastSegment(
          id: 's7',
          speaker: 'Host',
          text:
              'Packaging your own Python project is now genuinely pleasant. One pyproject.toml file declares '
              'the build backend, project name and version, dependencies, optional extras (like a [dev] group for testing tools), '
              'and console scripts — mapping a terminal command like "deploy" to a Python function. '
              'pip install -e . gives you editable mode during development — edit source, changes appear immediately. '
              'python -m build produces distributable wheels when you\'re ready to share. '
              'It went from "Python packaging is terrible" to "one file and done."',
          startMs: 392000,
          endMs: 452000,
        ),
        PodcastSegment(
          id: 's8',
          speaker: 'Guest',
          text:
              'And here\'s your nuclear option when things break: delete the environment and rebuild it. '
              'A venv holds nothing that isn\'t already recorded in your dependency files. '
              'rm -rf .venv, python -m venv .venv, pip install -e . — takes 30 seconds. '
              'If the problem survives a clean rebuild, you know it\'s your dependency declarations, not environmental cruft. '
              'That alone is worth the price of admission: it turns mysterious problems into actionable information.',
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
              'Alright, let\'s go deep on environments and packaging. Here\'s the analogy I want you to '
              'hold onto: imagine you\'re a carpenter who builds furniture, fixes plumbing, and does '
              'electronics. Would you throw every tool you own into one giant toolbox and hope for the '
              'best? Of course not — your plumbing wrench doesn\'t belong next to your soldering iron, '
              'and upgrading your hammer for furniture shouldn\'t break your pipe-fitting. That\'s '
              'exactly what virtual environments are: separate toolboxes per project. Today we\'re '
              'going to trace how an import actually finds a module on your disk, what a virtual '
              'environment changes about that search, how wheels differ from source distributions, '
              'what the build backend interface looks like under the hood, and how modern tools '
              'like uv and Poetry sit on top of the same standards without reinventing them.',
          startMs: 0,
          endMs: 64000,
        ),
        PodcastSegment(
          id: 'd2',
          speaker: 'Guest',
          text:
              'Let\'s start with import, because that\'s where every mystery begins. When you type '
              '"import requests", Python goes on a treasure hunt. It checks the script\'s directory first, '
              'then anything in PYTHONPATH, then the standard library, and finally site-packages. '
              'First match wins — like reaching into your toolbox and grabbing the first hammer you '
              'find. This ordering explains so many "why is my import broken?" moments. The classic '
              'one: you name a file random.py in your project, and suddenly the entire standard '
              'library random module disappears — your file is casting a shadow over it. '
              'Same goes for any name that collides with an installed package.',
          startMs: 64000,
          endMs: 152000,
        ),
        PodcastSegment(
          id: 'd3',
          speaker: 'Host',
          text:
              'So what does a virtual environment change? Exactly one thing: which site-packages '
              'folder appears on that search path. Think of it like a signpost, not a duplicate house. '
              'The pyvenv.cfg file inside .venv tells Python "hey, set sys.prefix to this directory," '
              'the site module then computes the site-packages path from that prefix, and the standard '
              'library still comes from the original base installation. This is why creating a venv takes '
              'a fraction of a second — it\'s not copying Python, it\'s just setting up a redirect. '
              'Like putting a sticky note on your toolbox saying "use this one instead."',
          startMs: 152000,
          endMs: 236000,
        ),
        PodcastSegment(
          id: 'd4',
          speaker: 'Guest',
          text:
              'There\'s a sneaky little flag in that config file called include-system-site-packages. '
              'Set it to true and your isolated toolbox suddenly has a window into the system-wide '
              'one — your venv can see packages installed globally. It sounds convenient, right? '
              '"I already have NumPy installed, why install it again?" But here\'s the trap: you '
              'just reintroduced invisible coupling. Your project now silently depends on whatever '
              'version happens to be on the system, and when you move to another machine or deploy, '
              'everything breaks. It\'s like saying "I\'ll just borrow my neighbor\'s tools" — works '
              'great until they move away. Leave it false unless you have a very specific, documented reason.',
          startMs: 236000,
          endMs: 310000,
        ),
        PodcastSegment(
          id: 'd5',
          speaker: 'Host',
          text:
              'Now let\'s talk distribution formats, because this is where "it works on my machine" '
              'often dies. A source distribution — an sdist — is like shipping someone a bag of flour, '
              'eggs, and sugar with a recipe. They have to bake the cake themselves, and if they '
              'don\'t have an oven or the right pan, they\'re stuck. A wheel, on the other hand, is '
              'the finished cake in a box — just unzip and serve. It\'s a zip archive with a '
              'standardized filename that encodes the Python version, ABI, and platform it targets. '
              'Installing a wheel is literally unzip-and-copy, which is why it\'s blazing fast and '
              'why the end user doesn\'t need a C compiler installed. Pure magic, but with a clear '
              'engineering reason behind it.',
          startMs: 310000,
          endMs: 398000,
        ),
        PodcastSegment(
          id: 'd6',
          speaker: 'Guest',
          text:
              'Here\'s where it gets practical. Pure-Python packages — no C code — produce one '
              'universal wheel that works everywhere. It\'s like a PDF: same file, any device. '
              'But anything with C extensions needs a wheel per platform — one for macOS, one for '
              'Windows, one for Linux. The manylinux standard exists to define a baseline of system '
              'libraries a Linux wheel can count on. When pip starts printing "building wheel for '
              'something" and then explodes with a missing header file error, you\'ve just learned '
              'that no pre-built wheel was published for your platform, so pip is trying to compile '
              'from source — and your machine isn\'t set up for it. It\'s like ordering a pre-built '
              'desk and getting a box of lumber instead because they were out of stock for your model.',
          startMs: 398000,
          endMs: 482000,
        ),
        PodcastSegment(
          id: 'd7',
          speaker: 'Host',
          text:
              'The build backend interface is the unsung hero making all of this work. You declare '
              'your build backend in pyproject.toml — maybe hatchling, maybe setuptools — and pip '
              'reads that, installs the backend into its own isolated temporary environment, then '
              'calls a set of well-defined hooks on it to produce the wheel. It\'s like a universal '
              'coffee pod machine: doesn\'t matter if the pod is from Nespresso, Keurig, or some '
              'artisan roaster — they all implement the same interface, so the machine just works. '
              'That\'s why hatchling, flit, setuptools, and poetry-core are interchangeable from the '
              'installer\'s perspective. They all speak the same build protocol. This standardization '
              'is what rescued Python packaging from the wild west of custom setup.py scripts.',
          startMs: 482000,
          endMs: 566000,
        ),
        PodcastSegment(
          id: 'd8',
          speaker: 'Guest',
          text:
              'Let\'s get precise about version specifiers, because sloppy versioning causes more '
              'production incidents than you\'d believe. Double-equals is a padlock — "requests==2.28.0" '
              'means exactly that and nothing else. Greater-than-or-equal sets a floor: '
              '"requests>=2.28" accepts anything newer. The tilde-equals is the compatible-release '
              'operator and it\'s the one people misuse most: "requests~=1.4.2" means "at least 1.4.2 '
              'but less than 1.5" — it only bumps the patch version. For libraries especially, '
              'set your floor at the oldest version you actually test against. Only add an upper '
              'bound like "<2.0" when you know for a fact that the next major release breaks your '
              'API. Upper bounds are constraints, and every unnecessary constraint is a potential '
              'conflict waiting to bite someone downstream.',
          startMs: 566000,
          endMs: 652000,
        ),
        PodcastSegment(
          id: 'd9',
          speaker: 'Host',
          text:
              'Now the tooling landscape, because you\'ll see a lot of names thrown around. uv, '
              'Poetry, PDM, Hatch — they all sit on top of the same standards and add a dependency '
              'resolver with a lock file, project scaffolding, and a convenient run command. Think '
              'of them as different brands of the same kitchen appliance — they all bake the cake, '
              'but the knobs and buttons are in different places. uv is dramatically faster because '
              'it\'s written in Rust with aggressive caching — it feels like going from dial-up to '
              'fiber. But here\'s the key thing none of the marketing tells you: every single one '
              'of these tools produces ordinary wheels from ordinary pyproject.toml files. There\'s '
              'no lock-in. You can switch from Poetry to uv and your package still builds. Pick '
              'based on workflow ergonomics, not fear of being trapped.',
          startMs: 652000,
          endMs: 728000,
        ),
        PodcastSegment(
          id: 'd10',
          speaker: 'Guest',
          text:
              'Two parting practices that will save you real pain. First: pipx. When you want '
              'a command-line tool available everywhere — black, ruff, httpie — use pipx install. '
              'It gives each tool its own hidden, isolated environment, so two tools with '
              'diametrically opposed dependency requirements can coexist happily. It\'s like giving '
              'each tool its own private apartment instead of making them share a dorm room. '
              'Second, and I cannot stress this enough: never, ever sudo pip install. The system '
              'Python belongs to your operating system. It\'s not yours to mess with — it\'s like '
              'borrowing the landlord\'s toolkit and swapping out their drill for a different one. '
              'Recent Python versions will flat-out refuse with an "externally managed environment" '
              'error, and that\'s a good thing. Use a venv for project work, pipx for global tools, '
              'and leave the system Python alone.',
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

const List<Source> _furtherReading = [
  Source(
    title: 'Packaging Python Projects — Python Packaging Authority',
    url: 'https://packaging.python.org/en/latest/tutorials/packaging-projects/',
    description:
        'The official PyPA tutorial on creating a pyproject.toml, choosing a '
        'build backend, and publishing to PyPI.',
  ),
  Source(
    title: 'Python Virtual Environments: A Primer — Real Python',
    url: 'https://realpython.com/python-virtual-environments-a-primer/',
    description:
        'Comprehensive guide to venv, activation/deactivation, pip, and '
        'common workflows for isolated development.',
  ),
  Source(
    title: 'importlib.metadata — Python Docs',
    url: 'https://docs.python.org/3/library/importlib.metadata.html',
    description:
        'Reference for programmatically reading installed package metadata: '
        'version, distributions, entry points, and requirements.',
  ),
  Source(
    title: 'PEP 517 – A build-system independent format for source trees',
    url: 'https://peps.python.org/pep-0517/',
    description:
        'The PEP that defined the pyproject.toml [build-system] table and '
        'standardised how build backends are invoked.',
  ),
];
