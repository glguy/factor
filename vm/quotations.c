#include "master.h"

/* Simple non-optimizing compiler.

This is one of the two compilers implementing Factor; the second one is written
in Factor and performs advanced optimizations. See core/compiler/compiler.factor.

The non-optimizing compiler compiles a quotation at a time by concatenating
machine code chunks; prolog, epilog, call word, jump to word, etc. These machine
code chunks are generated from Factor code in core/cpu/.../bootstrap.factor.

It actually does do a little bit of very simple optimization:

1) Tail call optimization.

2) If a quotation is determined to not call any other words (except for a few
special words which are open-coded, see below), then no prolog/epilog is
generated.

3) When in tail position and immediately preceded by literal arguments, the
'if' and 'dispatch' conditionals are generated inline, instead of as a call to
the 'if' word.

4) When preceded by an array, calls to the 'declare' word are optimized out
entirely. This word is only used by the optimizing compiler, and with the
non-optimizing compiler it would otherwise just decrease performance to have to
push the array and immediately drop it after.

5) Sub-primitives are primitive words which are implemented in assembly and not
in the VM. They are open-coded and no subroutine call is generated. This
includes stack shufflers, some fixnum arithmetic words, and words such as tag,
slot and eq?. A primitive call is relatively expensive (two subroutine calls)
so this results in a big speedup for relatively little effort. */

bool jit_primitive_call_p(F_ARRAY *array, CELL i)
{
	return (i + 2) == array_capacity(array)
		&& type_of(array_nth(array,i)) == FIXNUM_TYPE
		&& array_nth(array,i + 1) == userenv[JIT_PRIMITIVE_WORD];
}

bool jit_fast_if_p(F_ARRAY *array, CELL i)
{
	return (i + 3) == array_capacity(array)
		&& type_of(array_nth(array,i)) == QUOTATION_TYPE
		&& type_of(array_nth(array,i + 1)) == QUOTATION_TYPE
		&& array_nth(array,i + 2) == userenv[JIT_IF_WORD];
}

bool jit_fast_dispatch_p(F_ARRAY *array, CELL i)
{
	return (i + 2) == array_capacity(array)
		&& type_of(array_nth(array,i)) == ARRAY_TYPE
		&& array_nth(array,i + 1) == userenv[JIT_DISPATCH_WORD];
}

bool jit_ignore_declare_p(F_ARRAY *array, CELL i)
{
	return (i + 1) < array_capacity(array)
		&& type_of(array_nth(array,i)) == ARRAY_TYPE
		&& array_nth(array,i + 1) == userenv[JIT_DECLARE_WORD];
}

F_ARRAY *code_to_emit(CELL code)
{
	return untag_object(array_nth(untag_object(code),0));
}

F_REL rel_to_emit(CELL code, CELL code_format, CELL code_length,
	CELL rel_argument, bool *rel_p)
{
	F_ARRAY *quadruple = untag_object(code);
	CELL rel_class = array_nth(quadruple,1);
	CELL rel_type = array_nth(quadruple,2);
	CELL offset = array_nth(quadruple,3);

	F_REL rel;

	if(rel_class == F)
	{
		*rel_p = false;
		rel.type = 0;
		rel.offset = 0;
	}
	else
	{
		*rel_p = true;
		rel.type = to_fixnum(rel_type)
			| (to_fixnum(rel_class) << 8)
			| (rel_argument << 16);
		rel.offset = (code_length + to_fixnum(offset)) * code_format;
	}

	return rel;
}

#define EMIT(name,rel_argument) { \
		bool rel_p; \
		F_REL rel = rel_to_emit(name,code_format,code_count,rel_argument,&rel_p); \
		if(rel_p) GROWABLE_BYTE_ARRAY_APPEND(relocation,&rel,sizeof(F_REL)); \
		GROWABLE_ARRAY_APPEND(code,code_to_emit(name)); \
	}

bool jit_stack_frame_p(F_ARRAY *array)
{
	F_FIXNUM length = array_capacity(array);
	F_FIXNUM i;

	for(i = 0; i < length - 1; i++)
	{
		CELL obj = array_nth(array,i);
		if(type_of(obj) == WORD_TYPE)
		{
			F_WORD *word = untag_object(obj);
			if(word->subprimitive == F && obj != userenv[JIT_DECLARE_WORD])
				return true;
		}
	}

	return false;
}

void set_quot_xt(F_QUOTATION *quot, F_COMPILED *code)
{
	if(code->type != QUOTATION_TYPE)
		critical_error("bad param to set_quot_xt",(CELL)code);

	quot->code = code;
	quot->xt = (XT)(code + 1);
	quot->compiledp = T;
}

/* Might GC */
void jit_compile(CELL quot, bool relocate)
{
	if(untag_quotation(quot)->compiledp != F)
		return;

	CELL code_format = compiled_code_format();

	REGISTER_ROOT(quot);

	CELL array = untag_quotation(quot)->array;
	REGISTER_ROOT(array);

	GROWABLE_ARRAY(code);
	REGISTER_ROOT(code);

	GROWABLE_BYTE_ARRAY(relocation);
	REGISTER_ROOT(relocation);

	GROWABLE_ARRAY(literals);
	REGISTER_ROOT(literals);

	GROWABLE_ARRAY_ADD(literals,stack_traces_p() ? quot : F);

	bool stack_frame = jit_stack_frame_p(untag_object(array));

	if(stack_frame)
		EMIT(userenv[JIT_PROLOG],0);

	CELL i;
	CELL length = array_capacity(untag_object(array));
	bool tail_call = false;

	for(i = 0; i < length; i++)
	{
		CELL obj = array_nth(untag_object(array),i);
		F_WORD *word;
		F_WRAPPER *wrapper;

		switch(type_of(obj))
		{
		case WORD_TYPE:
			word = untag_object(obj);

			/* Intrinsics */
			if(word->subprimitive != F)
			{
				if(array_nth(untag_object(word->subprimitive),1) != F)
				{
					GROWABLE_ARRAY_ADD(literals,T);
				}

				EMIT(word->subprimitive,literals_count - 1);
			}
			else
			{
				GROWABLE_ARRAY_ADD(literals,array_nth(untag_object(array),i));

				if(i == length - 1)
				{
					if(stack_frame)
						EMIT(userenv[JIT_EPILOG],0);

					EMIT(userenv[JIT_WORD_JUMP],literals_count - 1);

					tail_call = true;
				}
				else
					EMIT(userenv[JIT_WORD_CALL],literals_count - 1);
			}
			break;
		case WRAPPER_TYPE:
			wrapper = untag_object(obj);
			GROWABLE_ARRAY_ADD(literals,wrapper->object);
			EMIT(userenv[JIT_PUSH_LITERAL],literals_count - 1);
			break;
		case FIXNUM_TYPE:
			if(jit_primitive_call_p(untag_object(array),i))
			{
				EMIT(userenv[JIT_PRIMITIVE],to_fixnum(obj));

				i++;

				tail_call = true;
				break;
			}
		case QUOTATION_TYPE:
			if(jit_fast_if_p(untag_object(array),i))
			{
				if(stack_frame)
					EMIT(userenv[JIT_EPILOG],0);

				GROWABLE_ARRAY_ADD(literals,array_nth(untag_object(array),i));
				GROWABLE_ARRAY_ADD(literals,array_nth(untag_object(array),i + 1));
				EMIT(userenv[JIT_IF_JUMP],literals_count - 2);

				i += 2;

				tail_call = true;
				break;
			}
		case ARRAY_TYPE:
			if(jit_fast_dispatch_p(untag_object(array),i))
			{
				if(stack_frame)
					EMIT(userenv[JIT_EPILOG],0);

				GROWABLE_ARRAY_ADD(literals,array_nth(untag_object(array),i));
				EMIT(userenv[JIT_DISPATCH],literals_count - 1);

				i++;

				tail_call = true;
				break;
			}
			else if(jit_ignore_declare_p(untag_object(array),i))
			{
				i++;
				break;
			}
		default:
			GROWABLE_ARRAY_ADD(literals,obj);
			EMIT(userenv[immediate_p(obj) ? JIT_PUSH_IMMEDIATE : JIT_PUSH_LITERAL],literals_count - 1);
			break;
		}
	}

	if(!tail_call)
	{
		if(stack_frame)
			EMIT(userenv[JIT_EPILOG],0);

		EMIT(userenv[JIT_RETURN],0);
	}

	GROWABLE_ARRAY_TRIM(code);
	GROWABLE_ARRAY_TRIM(literals);
	GROWABLE_BYTE_ARRAY_TRIM(relocation);

	F_COMPILED *compiled = add_compiled_block(
		QUOTATION_TYPE,
		untag_object(code),
		NULL,
		relocation,
		untag_object(literals));

	set_quot_xt(untag_object(quot),compiled);

	if(relocate)
		iterate_code_heap_step(compiled,relocate_code_block);

	UNREGISTER_ROOT(literals);
	UNREGISTER_ROOT(relocation);
	UNREGISTER_ROOT(code);
	UNREGISTER_ROOT(array);
	UNREGISTER_ROOT(quot);
}

/* Crappy code duplication. If C had closures (not just function pointers)
it would be easy to get rid of, but I can't think of a good way to deal
with it right now that doesn't involve lots of boilerplate that would be
worse than the duplication itself (eg, putting all state in some global
struct.) */
#define COUNT(name,scan) \
	{ \
		if(offset == 0) return scan - 1; \
		offset -= array_capacity(code_to_emit(name)) * code_format; \
	}

F_FIXNUM quot_code_offset_to_scan(CELL quot, F_FIXNUM offset)
{
	CELL code_format = compiled_code_format();

	CELL array = untag_quotation(quot)->array;

	bool stack_frame = jit_stack_frame_p(untag_object(array));

	if(stack_frame)
		COUNT(userenv[JIT_PROLOG],0)

	CELL i;
	CELL length = array_capacity(untag_object(array));
	bool tail_call = false;

	for(i = 0; i < length; i++)
	{
		CELL obj = array_nth(untag_object(array),i);
		F_WORD *word;

		switch(type_of(obj))
		{
		case WORD_TYPE:
			/* Intrinsics */
			word = untag_object(obj);
			if(word->subprimitive != F)
				COUNT(word->subprimitive,i)
			else if(i == length - 1)
			{
				if(stack_frame)
					COUNT(userenv[JIT_EPILOG],i);

				COUNT(userenv[JIT_WORD_JUMP],i)

				tail_call = true;
			}
			else
				COUNT(userenv[JIT_WORD_CALL],i)
			break;
		case WRAPPER_TYPE:
			COUNT(userenv[JIT_PUSH_LITERAL],i)
			break;
		case FIXNUM_TYPE:
			if(jit_primitive_call_p(untag_object(array),i))
			{
				COUNT(userenv[JIT_PRIMITIVE],i);

				i++;

				tail_call = true;
				break;
			}
		case QUOTATION_TYPE:
			if(jit_fast_if_p(untag_object(array),i))
			{
				if(stack_frame)
					COUNT(userenv[JIT_EPILOG],i)

				i += 2;

				COUNT(userenv[JIT_IF_JUMP],i)

				tail_call = true;
				break;
			}
		case ARRAY_TYPE:
			if(jit_fast_dispatch_p(untag_object(array),i))
			{
				if(stack_frame)
					COUNT(userenv[JIT_EPILOG],i)

				i++;

				COUNT(userenv[JIT_DISPATCH],i)

				tail_call = true;
				break;
			}
			if(jit_ignore_declare_p(untag_object(array),i))
			{
				if(offset == 0) return i;

				i++;

				break;
			}
		default:
			COUNT(userenv[immediate_p(obj) ? JIT_PUSH_IMMEDIATE : JIT_PUSH_LITERAL],i)
			break;
		}
	}

	if(!tail_call)
	{
		if(stack_frame)
			COUNT(userenv[JIT_EPILOG],length)

		COUNT(userenv[JIT_RETURN],length)
	}

	return -1;
}

F_FASTCALL CELL primitive_jit_compile(CELL quot, F_STACK_FRAME *stack)
{
	stack_chain->callstack_top = stack;
	REGISTER_ROOT(quot);
	jit_compile(quot,true);
	UNREGISTER_ROOT(quot);
	return quot;
}

/* push a new quotation on the stack */
DEFINE_PRIMITIVE(array_to_quotation)
{
	F_QUOTATION *quot = allot_object(QUOTATION_TYPE,sizeof(F_QUOTATION));
	quot->array = dpeek();
	quot->xt = lazy_jit_compile;
	quot->compiledp = F;
	drepl(tag_object(quot));
}

DEFINE_PRIMITIVE(quotation_xt)
{
	F_QUOTATION *quot = untag_quotation(dpeek());
	drepl(allot_cell((CELL)quot->xt));
}
