; Check that a spilled value whose type is more aligned than the async context
; does not desync the frame layout from the frame type.
;
; <4 x double> has a 32 byte ABI alignment, but swift_task_alloc only guarantees
; the async context alignment (16 here). FrameTypeBuilder therefore lowers the
; field's alignment to 16 and emits the spill accesses at that alignment. The
; frame type must be packed so that DataLayout does not re-impose the 32 byte
; alignment and shift every following field out from under the offsets, and the
; context size, that the layout already committed to.

; RUN: opt < %s -passes='coro-early,cgscc(coro-split)' -S | FileCheck %s

target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx15.0.0"

%async.ctxt = type { ptr, ptr }

@my_other_async_function_fp = external global <{ i32, i32 }>
declare void @my_other_async_function(ptr)

@my_async_function_fp = constant <{ i32, i32 }>
  <{ i32 trunc (
       i64 sub (
         i64 ptrtoint (ptr @my_async_function to i64),
         i64 ptrtoint (ptr getelementptr inbounds (<{ i32, i32 }>, ptr @my_async_function_fp, i32 0, i32 1) to i64)
       )
     to i32),
     i32 16
}>

declare void @opaque(ptr)
declare ptr @llvm.coro.async.context.alloc(ptr, ptr)
declare void @llvm.coro.async.context.dealloc(ptr)
declare ptr @llvm.coro.async.resume()
declare token @llvm.coro.id.async(i32, i32, i32, ptr)
declare ptr @llvm.coro.begin(token, ptr)
declare i1 @llvm.coro.end.async(ptr, i1, ...)
declare swiftcc void @asyncReturn(ptr)
declare swiftcc void @asyncSuspend(ptr)
declare {ptr} @llvm.coro.suspend.async(i32, ptr, ptr, ...)

define swiftcc void @my_async_function.my_other_async_function_fp.apply(ptr %fnPtr, ptr %async.ctxt) {
  tail call swiftcc void %fnPtr(ptr %async.ctxt)
  ret void
}

define ptr @__swift_async_resume_project_context(ptr %ctxt) {
entry:
  %resume_ctxt = load ptr, ptr %ctxt, align 8
  ret ptr %resume_ctxt
}

; The frame must be a packed struct, so that the <4 x double> keeps the offset
; the layout assigned it rather than being re-aligned to 32 by DataLayout.
; CHECK: %my_async_function.Frame = type <{ {{.*}}<4 x double>{{.*}} }>

define swiftcc void @my_async_function(ptr swiftasync %async.ctxt, ptr %in, ptr %out) presplitcoroutine {
entry:
  %id = call token @llvm.coro.id.async(i32 16, i32 16, i32 0,
          ptr @my_async_function_fp)
  %hdl = call ptr @llvm.coro.begin(token %id, ptr null)

  ; A 48 byte alloca, laid out ahead of the vector below because it is larger,
  ; which lands the vector on a 16 but not 32 byte aligned offset.
  %big = alloca [48 x i8], align 16

  ; Spills that are not a multiple of 32 bytes, so that the vector below cannot
  ; land on a 32 byte boundary by luck.
  %word = load i64, ptr %in, align 8
  %ref = load ptr, ptr %in, align 8

  ; The over-aligned spill.
  %vec = load <4 x double>, ptr %in, align 16

  %callee_context = call ptr @llvm.coro.async.context.alloc(ptr null, ptr null)
  %callee_context.return_to_caller.addr = getelementptr inbounds %async.ctxt, ptr %callee_context, i32 0, i32 1
  %resume.func_ptr = call ptr @llvm.coro.async.resume()
  store ptr %resume.func_ptr, ptr %callee_context.return_to_caller.addr

  %res = call {ptr} (i32, ptr, ptr, ...) @llvm.coro.suspend.async(i32 0,
                                                  ptr %resume.func_ptr,
                                                  ptr @__swift_async_resume_project_context,
                                                  ptr @my_async_function.my_other_async_function_fp.apply,
                                                  ptr @asyncSuspend, ptr %callee_context)

  store <4 x double> %vec, ptr %out, align 16
  store i64 %word, ptr %out, align 8
  store ptr %ref, ptr %out, align 8
  call void @opaque(ptr %big)
  call void @llvm.coro.async.context.dealloc(ptr %callee_context)
  tail call swiftcc void @asyncReturn(ptr %async.ctxt)
  call i1 (ptr, i1, ...) @llvm.coro.end.async(ptr %hdl, i1 0)
  unreachable
}
