/*
	Offsets for the kernel
*/

#include <mach/mach.h>

#ifndef OFFSETS_H_
#define OFFSETS_H_

#define REALHOST_SPECIAL_4_OFF  0x30
#define TASK_ITK_SELF_OFF       0xd8

#define RAW_OFFSET(offset)									offsets_get_offsets().offset

typedef struct offsets_e {
    uint64_t main_kernel_base; // used by extra_recipe.. (not same as g_kernel_base)
	uint64_t kernel_base;
    uint64_t kernel_text;
    
	uint64_t encode_frame_offset_chroma_format_idc;
	uint64_t encode_frame_offset_ui32_width;
	uint64_t encode_frame_offset_ui32_height;
	uint64_t encode_frame_offset_slice_per_frame;
	uint64_t encode_frame_offset_info_type;
	uint64_t encode_frame_offset_iosurface_buffer_mgr;
	uint64_t kernel_address_multipass_end_pass_counter_enc;
	uint64_t encode_frame_offset_keep_cache;
	uint64_t iofence_vtable_offset;
	uint64_t iosurface_current_fences_list_head;
	uint64_t panic;
	uint64_t osserializer_serialize;
	uint64_t copyin;
	uint64_t copyout;
	uint64_t all_proc;
	uint64_t kern_proc;
    uint64_t kernel_task;
    uint64_t realhost;
    uint64_t bzero;
    uint64_t bcopy;
    uint64_t iosurfacerootuserclient_vtable;
    uint64_t ROP_ADD_X0_X0_0x10;
	uint64_t l1dcachesize_handler;
	uint64_t l1dcachesize_string;
	uint64_t l1icachesize_string;
	uint64_t quad_format_string;
	uint64_t null_terminator;
	uint64_t cachesize_callback;
	uint64_t sysctl_hw_family;
	uint64_t ret_gadget;
	uint64_t struct_proc_p_comm;
	uint64_t struct_proc_p_ucred;
	uint64_t struct_kauth_cred_cr_ref;
	uint64_t struct_proc_p_uthlist;
	uint64_t struct_uthread_uu_ucred;
    uint64_t struct_uthread_uu_list;
    uint64_t iosurface_vtable_offset_kernel_hijack;
    
    // mounting
    uint64_t mount_common;
    uint64_t vfs_context_current;
    uint64_t copyinstr;
    
    // following used for the kernel task port
    uint64_t kernel_map;
    uint64_t zone_map;
    uint64_t ipc_space_kernel;
    uint64_t ipc_kobject_set;
    uint64_t mach_vm_wire;
    uint64_t mach_vm_remap;
    uint64_t ipc_port_make_send;
    uint64_t ipc_port_alloc_special;

	// Static addresses for hardcoded JOP gadgets used in kernel_call.
	// The address is 0 if the gadget is not known to be present.
	// call_strategy_3:
	uint64_t jop_GADGET_PROLOGUE_1;
	uint64_t jop_LDP_X2_X1_X1__BR_X2;
	uint64_t jop_MOV_X23_X0__BLR_X8;
	uint64_t jop_GADGET_INITIALIZE_X20_1;
	uint64_t jop_MOV_X25_X0__BLR_X8;
	uint64_t jop_GADGET_POPULATE_1;
	uint64_t jop_MOV_X19_X9__BR_X8;
	uint64_t jop_MOV_X20_X12__BR_X8;
	uint64_t jop_MOV_X21_X5__BLR_X8;
	uint64_t jop_MOV_X22_X6__BLR_X8;
	uint64_t jop_MOV_X0_X3__BLR_X8;
	uint64_t jop_MOV_X24_X4__BR_X8;
	uint64_t jop_MOV_X8_X10__BR_X11;
	uint64_t jop_GADGET_CALL_FUNCTION_1;
	uint64_t jop_GADGET_STORE_RESULT_1;
	uint64_t jop_GADGET_EPILOGUE_1;
	// call_strategy_4:
	uint64_t jop_GADGET_PROLOGUE_2;
	uint64_t jop_MOV_X25_X19__BLR_X8;
	uint64_t jop_GADGET_POPULATE_2;
	uint64_t jop_MOV_X19_X5__BLR_X8;
	uint64_t jop_MOV_X20_X19__BR_X8;
	uint64_t jop_MOV_X5_X6__BLR_X8;
	uint64_t jop_MOV_X21_X11__BLR_X8;
	uint64_t jop_MOV_X22_X9__BLR_X8;
	uint64_t jop_MOV_X8_X10__BR_X12;
	uint64_t jop_GADGET_EPILOGUE_2;

    // not really offsets but eh
    char * driver_name;
    int add_client_input_buffer_size;
    int encode_frame_input_buffer_size;
    int encode_frame_output_buffer_size;
    uint64_t iosurface_kernel_object_size;
    
} offsets_t;

kern_return_t offsets_init();
offsets_t offsets_get_offsets();
uint64_t offsets_get_kernel_base();
void offsets_set_kernel_base(uint64_t kernel_base);

kern_return_t set_driver_offsets(char * driver_name);

// offsets from the main kernel 0xfeedfacf
extern uint64_t allproc_offset;
extern uint64_t kernproc_offset;

// offsets in struct proc
extern uint64_t struct_proc_p_pid_offset;
extern uint64_t struct_proc_task_offset;
extern uint64_t struct_proc_p_uthlist_offset;
extern uint64_t struct_proc_p_ucred_offset;
extern uint64_t struct_proc_p_comm_offset;

// offsets in struct kauth_cred
extern uint64_t struct_kauth_cred_cr_ref_offset;

// offsets in struct uthread
extern uint64_t struct_uthread_uu_ucred_offset;
extern uint64_t struct_uthread_uu_list_offset;

// offsets in struct task
extern uint64_t struct_task_ref_count_offset;
extern uint64_t struct_task_itk_space_offset;

// offsets in struct ipc_space
extern uint64_t struct_ipc_space_is_table_offset;

// offsets in struct ipc_port
extern uint64_t struct_ipc_port_ip_kobject_offset;

void init_offsets();
extern uint64_t rootvnode_offset;

// kppless ---
extern unsigned offsetof_p_pid;
extern unsigned offsetof_task;
extern unsigned offsetof_p_ucred;
extern unsigned offsetof_p_comm;
extern unsigned offsetof_p_csflags;
extern unsigned offsetof_itk_self;
extern unsigned offsetof_itk_sself;
extern unsigned offsetof_itk_bootstrap;
extern unsigned offsetof_ip_mscount;
extern unsigned offsetof_ip_srights;
extern unsigned offsetof_special;

#define CS_PLATFORM_BINARY	0x4000000	/* this is a platform binary */
#define CS_INSTALLER		0x0000008	/* has installer entitlement */
#define CS_GET_TASK_ALLOW	0x0000004	/* has get-task-allow entitlement */
#define CS_RESTRICT		0x0000800	/* tell dyld to treat restricted */
#define	CS_HARD			0x0000100	/* don't load invalid pages */
#define	CS_KILL			0x0000200	/* kill process if it becomes invalid */

#endif /* OFFSETS_H_ */
