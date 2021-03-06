#ifndef GLOBAL_SCHEDULER_H
#define GLOBAL_SCHEDULER_H

#include "task.h"

#include "state/db.h"
#include "state/local_scheduler_table.h"
#include "utarray.h"
#include "uthash.h"

/* The frequency with which the global scheduler checks if there are any tasks
 * that haven't been scheduled yet. */
#define GLOBAL_SCHEDULER_TASK_CLEANUP_MILLISECONDS 100

/** Contains all information that is associated with a local scheduler. */
typedef struct {
  /** The ID of the local scheduler in Redis. */
  DBClientID id;
  /** The number of tasks sent from the global scheduler to this local
   *  scheduler. */
  int64_t num_tasks_sent;
  /** The number of tasks sent from the global scheduler to this local scheduler
   *  since the last heartbeat arrived. */
  int64_t num_recent_tasks_sent;
  /** The latest information about the local scheduler capacity. This is updated
   *  every time a new local scheduler heartbeat arrives. */
  LocalSchedulerInfo info;
} LocalScheduler;

typedef struct GlobalSchedulerPolicyState GlobalSchedulerPolicyState;

/**
 * This defines a hash table used to cache information about different objects.
 */
typedef struct {
  /** The object ID in question. */
  ObjectID object_id;
  /** The size in bytes of the object. */
  int64_t data_size;
  /** An array of object locations for this object. */
  UT_array *object_locations;
  /** Handle for the uthash table. */
  UT_hash_handle hh;
} SchedulerObjectInfo;

/**
 * A struct used for caching Photon to Plasma association.
 */
typedef struct {
  /** IP:port string for the plasma_manager. */
  char *aux_address;
  /** Photon db client id. */
  DBClientID photon_db_client_id;
  /** Plasma_manager ip:port -> photon_db_client_id. */
  UT_hash_handle plasma_photon_hh;
  /** Photon_db_client_id -> plasma_manager ip:port. */
  UT_hash_handle photon_plasma_hh;
} AuxAddressEntry;

/**
 * Global scheduler state structure.
 */
typedef struct {
  /** The global scheduler event loop. */
  event_loop *loop;
  /** The global state store database. */
  DBHandle *db;
  /** The local schedulers that are connected to Redis. TODO(rkn): This probably
   *  needs to be a hashtable since we often look up the local_scheduler struct
   *  based on its db_client_id. */
  UT_array *local_schedulers;
  /** The state managed by the scheduling policy. */
  GlobalSchedulerPolicyState *policy_state;
  /** The plasma_manager ip:port -> photon_db_client_id association. */
  AuxAddressEntry *plasma_photon_map;
  /** The photon_db_client_id -> plasma_manager ip:port association. */
  AuxAddressEntry *photon_plasma_map;
  /** Objects cached by this global scheduler instance. */
  SchedulerObjectInfo *scheduler_object_info_table;
  /** An array of tasks that haven't been scheduled yet. */
  UT_array *pending_tasks;
} GlobalSchedulerState;

/**
 * This is a helper method to look up the local scheduler struct that
 * corresponds to a particular photon_id.
 *
 * @param state The state of the global scheduler.
 * @param The photon_id of the local scheduler.
 * @return The corresponding local scheduler struct. If the global scheduler is
 *         not aware of the local scheduler, then this will be NULL.
 */
LocalScheduler *get_local_scheduler(GlobalSchedulerState *state,
                                    DBClientID photon_id);

/**
 * Assign the given task to the local scheduler, update Redis and scheduler data
 * structures.
 *
 * @param state Global scheduler state.
 * @param task Task to be assigned to the local scheduler.
 * @param local_scheduler_id DB client ID for the local scheduler.
 * @return Void.
 */
void assign_task_to_local_scheduler(GlobalSchedulerState *state,
                                    Task *task,
                                    DBClientID local_scheduler_id);

#endif /* GLOBAL_SCHEDULER_H */
