package karl2d_hot_reload_build

import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:time"

main :: proc() {
	OUT_DIR :: "bin/hot_reload"
    PDB_DIR :: OUT_DIR + "/pdbs"
    when ODIN_OS == .Windows {
        DLL_EXT :: ".dll"
        ODIN_EXE :: "odin.exe"
        PDB_ARG ::  fmt.tprintf("-pdb-name:%s/game_%i.pdb", PDB_DIR, pdb_number)
    } else when ODIN_OS == .Darwin {
        ODIN_EXE :: "odin"
        DLL_EXT :: ".dylib"
        PDB_ARG :: ""
    } else {
        ODIN_EXE :: "odin"
        DLL_EXT :: ".so"
        PDB_ARG :: ""
    }
	EXE :: "game_hot_reload" + DLL_EXT

	pids, pids_err := os.process_list(context.allocator)

	if pids_err != nil {
		fmt.println("Failed to list processes")
		return
	}

	game_running := false

	for pid in pids {
		info, info_err := os.process_info_by_pid(pid, {.Executable_Path}, context.allocator)

		if info_err == nil {
			if filepath.base(info.executable_path) == EXE {
				game_running = true
				break
			}
		}
	}

	if !game_running {
		os.remove_all(OUT_DIR)
		os.remove_all(PDB_DIR)
		os.make_directory_all(PDB_DIR)
	}
	
	pdb_number := time.to_unix_nanoseconds(time.now())

	fmt.println("Building game DLL...")

	build_game_state, _, build_game_errmsg, build_game_err := os.process_exec(
		desc = {
			command = {
                ODIN_EXE,
				"build",
				"game",
				"-debug",
				"-build-mode:dll",
				"-out:" + OUT_DIR + "/game.so",
                PDB_ARG
			},
		},
		allocator = context.allocator,
	)

	if build_game_err != nil {
		fmt.eprintln("Failed to build game DLL:", build_game_err)
		os.exit(1)
	}

	if build_game_state.exit_code != 0 {
		fmt.eprintln("Failed to build game DLL:", string(build_game_errmsg), sep = "\n")
		os.exit(1)
	}

	if game_running {
		fmt.println("Hot reloading...")
		os.exit(0)
	}

	fmt.println("Building game EXE...")

	build_exe_state, _, build_exe_errmsg, build_exe_err := os.process_exec(
		desc = {
			command = {
                ODIN_EXE,
				"build",
				"main_hot_reload",
				"-debug",
                "-out:" + OUT_DIR + "/" + EXE,
			},
		},
		allocator = context.allocator,
	)

	if build_exe_err != nil {
		fmt.eprintln("Failed to build game EXE:", build_exe_err)
		os.exit(1)
	}

	if build_exe_state.exit_code != 0 {
		fmt.eprintln("Failed to build game EXE:", string(build_exe_errmsg), sep = "\n")
		os.exit(1)
	}
}
