#include <stddef.h>
#include "ll_cycle.h"

/* TODO: 判断一个单链表是否循环
参数： head 单链表头节点
返回值： 1 为循环， 0为不循环
*/
int ll_has_cycle(node *head) {
    
    /*  算法如下：
        1. 设置两个节点，一个记作乌龟，一个记作兔子
        2. 兔子向后移动两个节点， 如果遇到NULL, 则结束， 无循环
        3. 乌龟向后移动一个节点
        4. 查看此时兔子和乌龟是否指向同一个节点， 如果是，则循环，如果不是，返回至步骤2
        只要有环，兔子一定会先进入环中，乌龟后进入，此时兔子沿环方向距离乌龟距离一定为一个常数，
        乌龟和兔子相对速度为1， 在常数轮次下， 乌龟兔子必然相遇
    */
    if(head != NULL && head->next != NULL && head->next->next != NULL){
        node* turtle = head->next;
        node* rabbit = head->next->next;
        while(rabbit->next != NULL && rabbit->next->next != NULL){
            if(turtle == rabbit) return 1;
            rabbit = rabbit->next->next;
            turtle = turtle->next;
        }
    }
    return 0;
}