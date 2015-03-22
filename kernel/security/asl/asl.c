#include <linux/kernel.h>
#include <asm/uaccess.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>

#define ASL_ENTRY "asl"
#ifdef CONFIG_ASL_DISABLED
#define ENABLED_FLAG "0"
#else
#define ENABLED_FLAG "1"
#endif
#define ASL_version "1.0"
#define MAX_PROC_SIZE 4 //размер буфера для записи статуса

static char files_count[] = {
#include "files_count"
};
static char root_hash[] = {
#include "root_hash"
};
static char proc_data[MAX_PROC_SIZE];

static struct proc_dir_entry *asl_dir;
static struct proc_dir_entry *enabled_file; //вкл/откл механизма
static struct proc_dir_entry *status_file; //переменная для статуса
static struct proc_dir_entry *version_file; //переменная для версии
static struct proc_dir_entry *root_hash_file; //переменная для корневой хеш суммы
static struct proc_dir_entry *files_count_file; //переменная для количества файлов

int read_enabled_flag(char *buf,char **start,off_t offset,int count,int *eof,void *data )
{
int len=0;
len = sprintf(buf,ENABLED_FLAG);
return len;
}

int read_files_count(char *buf,char **start,off_t offset,int count,int *eof,void *data )
{
int len=0;
len = sprintf(buf,files_count);
return len;
}

int read_root_hash(char *buf,char **start,off_t offset,int count,int *eof,void *data )
{
int len=0;
len = sprintf(buf,root_hash);
return len;
}

int read_ver(char *buf,char **start,off_t offset,int count,int *eof,void *data )
{
int len=0;
len = sprintf(buf,ASL_version);
return len;
}

int read_proc(char *buf,char **start,off_t offset,int count,int *eof,void *data )
{
int len=0;
len = sprintf(buf,"\n %s\n ",proc_data);
return len;
}

int write_proc(struct file *file,const char *buf,int count,void *data )
{

if(count > MAX_PROC_SIZE)
    count = MAX_PROC_SIZE;
if(copy_from_user(proc_data, buf, count))
    return -EFAULT;

return count;
}


void create_new_proc_entry()
{
asl_dir = proc_mkdir(ASL_ENTRY,NULL);
if(!asl_dir){
    printk(KERN_INFO "Error creating asl proc dir");
    return -ENOMEM;
}
enabled_file = create_proc_read_entry("enabled", 0444, asl_dir, read_enabled_flag, NULL);
files_count_file = create_proc_read_entry("files_count", 0444, asl_dir, read_files_count, NULL);
root_hash_file = create_proc_read_entry("root_hash", 0444, asl_dir, read_root_hash, NULL);
version_file = create_proc_read_entry("version", 0444, asl_dir, read_ver, NULL);
status_file = create_proc_entry("status", 0666, asl_dir);
if(!status_file){
    printk(KERN_INFO "Error creating asl proc entry");
    return -ENOMEM;
}
status_file->read_proc = read_proc;
status_file->write_proc = write_proc;
printk(KERN_INFO "asl proc initialized");

}

int asl_init (void) {
    create_new_proc_entry();
    return 0;
}

module_init(asl_init);
