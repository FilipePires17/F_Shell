/* queue.h: queue implemented with a circular, doubly-linked list with a
   sentinel */
/* Do not change this file */

#ifndef QUEUE_H
#define QUEUE_H

#include <stddef.h>

typedef struct node {
    struct node *prev, *next;
} node_t;

/* Initialize a queue */
void queue_init(node_t * queue);

/* Remove and return the item at the front of the queue Return NULL if the
   queue is empty */
node_t *dequeue(node_t * queue);

/* Add item to the back of the queue */
void enqueue(node_t * queue, node_t * item);

/* Determine if the queue is empty.
 * Returns 1 if the queue is empty.
 * Returns 0 otherwise.
 */
int is_empty(node_t *queue);

/* Returns the first item in the queue
 * Returns NULL if the queue is empty
 */
node_t *peek(node_t *queue);

#endif                          /* QUEUE_H */
