package main


persist_add :: proc(val: $T) -> T {
	@(static) local_val: T
	local_val += val

	return local_val
}
