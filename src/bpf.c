// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wduplicate-decl-specifier"  // for now we acknowledge the kernel 6.12+ warnings

#include <uapi/linux/ptrace.h>
#include <bcc/proto.h>
#include <linux/sched.h>

// Forward declarations to fix kernel 6.12+ compatibility
struct bpf_wq;
struct bpf_rb_root;
struct bpf_rb_node;
struct bpf_refcount;

#include <net/sock.h>

#pragma clang diagnostic pop

#define IP_169_254_169_254 0xFEA9FEA9

#define MAX_PKT 31*1024
struct imds_http_data_t {
    u32 pid[4];
    // i could not get 2d type conversion right in python, so...
    char comm[TASK_COMM_LEN];
    char parent_comm[TASK_COMM_LEN];
    char gparent_comm[TASK_COMM_LEN];
    char ggparent_comm[TASK_COMM_LEN];
    u32 pkt_size;
    char pkt[MAX_PKT];
    u32 contains_payload;
};
BPF_PERF_OUTPUT(imds_events);

// single element per-cpu array to hold the current event off the stack
BPF_PERCPU_ARRAY(imds_http_data,struct imds_http_data_t,1);

int trace_sock_sendmsg(struct pt_regs *ctx)
{
    // stash the sock ptr for lookup on return
    // only if it is imds traffic
    struct socket *skt = (struct socket *)PT_REGS_PARM1(ctx);
    struct sock *sk = skt->sk;
    if (sk->__sk_common.skc_daddr == IP_169_254_169_254) {
        struct msghdr *msghdr = (struct msghdr *)PT_REGS_PARM2(ctx);
        u32 zero = 0;

        // pull in details
        u32 daddr = sk->__sk_common.skc_daddr;
        u16 dport = sk->__sk_common.skc_dport;

        struct imds_http_data_t *data = imds_http_data.lookup(&zero);

        if (!data) // this should never happen, just making the verifier happy
          return 0;

        #if defined(iter_iov) || defined (iter_iov_len)
        const struct iovec * iov = msghdr->msg_iter.__iov;
        #else
        const struct iovec * iov = msghdr->msg_iter.iov;
        #endif
        const void *iovbase;
        if (*(char *)iov->iov_base == '\0'){
          iovbase = iov;
        }
        else{
          iovbase = iov->iov_base;
        }
        const size_t iovlen = iov->iov_len > MAX_PKT ? MAX_PKT : iov->iov_len;
        
        if (!iovlen) {
          return 0;
        }

        //The size parameter in the line of code below seems to be incorrectly set
        //however if we were to intuitively use the size of the payload itself as the size parameter by using iovlen (size of the payload) 
        //the interpreter will throw an invalid mem access error and the script will not run (most probably due to the method requiring a const value at compile time)
        bpf_probe_read_str(data->pkt, sizeof(data->pkt), iovbase);
        
        //check if payload is empty or not -> check char buffer -> if char buffer starts with a termination vales \0 => null buffer
        if(data->pkt[0] == '\0'){
          data->contains_payload = 0;
        }
        else{
          data->contains_payload = 1;
        }
        
        data->pkt_size = iovlen;

        struct task_struct *t = (struct task_struct *)bpf_get_current_task();
        data->pid[0] = t->tgid;
        bpf_probe_read(data->comm, TASK_COMM_LEN, t->comm);
        // loops not supported in bpf
        if (t->real_parent) {
          struct task_struct *parent = t->real_parent;
          data->pid[1] = parent->tgid;
          bpf_probe_read(data->parent_comm, TASK_COMM_LEN, parent->comm);
          if (parent->real_parent) {
            struct task_struct *gparent = parent->real_parent;
            data->pid[2] = gparent->tgid;
            bpf_probe_read(data->gparent_comm, TASK_COMM_LEN, gparent->comm);
            if (gparent->real_parent) {
              struct task_struct *ggparent = gparent->real_parent;
              bpf_probe_read(data->ggparent_comm, TASK_COMM_LEN, ggparent->comm);
              data->pid[3] = ggparent->tgid;
            }
          }
        }


        imds_events.perf_submit(ctx, data, sizeof(struct imds_http_data_t));
    }

   return 0;

}
