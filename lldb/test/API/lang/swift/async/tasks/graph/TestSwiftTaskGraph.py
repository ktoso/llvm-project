import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import TestBase
import lldbsuite.test.lldbutil as lldbutil

class TestCase(TestBase):

    @skipUnlessPlatform(["macosx"])
    @swiftTest
    def test_task_graph(self):
        self.build()
        _, _, thread, _ = lldbutil.run_to_source_breakpoint(
            self, "break here", lldb.SBFileSpec("main.swift")
        )
        self.runCmd("language swift task graph --max-frames 1")

        # (lldb) task graph --max-frames 1
        # ├╴ Task 1 (addr = 0x105192490)
        # │    frame #0: Task<>.value.getter at Task.swift:277:7
        # └╴ Task 2 (addr = 0x1051939b0)
        #    │ frame #0: factorial(n:) at main.swift:7
        #    └╴ Task 3 (addr = 0x105194490)
        #       │ frame #0: factorial(n:) at main.swift:7
        #       └╴ Task 4 (addr = 0x105194890)
        #            frame #0: factorial(n:) + 60 at main.swift:3:5

        result = self.res.GetOutput().splitlines()

        self.assertRegex(result[0], r"Task 1 \(addr = 0x[0-9a-fA-F]+\) awaiting task id = 2")
        self.assertRegex(result[1], r"frame #0: Task<>.value.getter")

        result = result[2:]
        self.assertRegex(result[0], r"Task 2 \(addr = 0x[0-9a-fA-F]+\)")
        self.assertRegex(result[1], r"frame #0: factorial.* at main.swift:7")
        self.assertRegex(result[2], r"Task 3 \(addr = 0x[0-9a-fA-F]+\)")
        self.assertRegex(result[3], r"frame #0: factorial.* at main.swift:7")
        self.assertRegex(result[4], r"Task 4 \(addr = 0x[0-9a-fA-F]+\)")
        self.assertRegex(result[5], r"frame #0: factorial.* at main.swift:3")
