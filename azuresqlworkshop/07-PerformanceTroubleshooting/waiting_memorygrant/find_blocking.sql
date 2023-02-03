;with cteHead as (
	select 
		sess.session_id
		,req.request_id
		,left(isnull(req.wait_type, ''), 50) as 'wait_type'
		,left(isnull(req.wait_resource, ''), 40) as 'wait_resource'
		,left(req.last_wait_type, 50) as 'last_wait_type'
		,sess.is_user_process
		,req.cpu_time as 'request_cpu_time'
		,req.logical_reads as 'request_logical_reads'
		,req.reads as 'request_reads'
		,req.writes as 'request_writes'
		,req.wait_time
		,req.blocking_session_id
		,sess.memory_usage
		,sess.cpu_time as 'session_cpu_time'
		,sess.reads as 'session_reads'
		,sess.writes as 'session_writes'
		,sess.logical_reads as 'session_logical_reads'
		,convert(decimal(5, 2), req.percent_complete) as 'percent_complete'
		,req.estimated_completion_time AS 'est_completion_time'
		,req.start_time as 'request_start_time'
		,left(req.[status], 15) as 'request_status'
		,sess.open_transaction_count as 'open_tran_count'
		,req.command
		,req.plan_handle
		,req.[sql_handle]
		,req.statement_start_offset
		,req.statement_end_offset
		,conn.most_recent_sql_handle
		,left(sess.[status], 15) AS 'session_status'
		,sess.group_id
		,req.query_hash
		,req.query_plan_hash
    from 
		sys.dm_exec_sessions as sess
		left outer join sys.dm_exec_requests as req 
			on (sess.session_id = req.session_id)
		left outer join sys.dm_exec_connections as conn 
			on (conn.session_id = sess.session_id )
)
,cteBlockingHierarchy as (
	select 
		head.session_id as head_blocker_session_id
		,head.session_id as session_id
		,head.blocking_session_id
		,head.request_status
		,head.open_tran_count
		,head.wait_type
		,head.wait_time
		,head.wait_resource
		,head.[sql_handle]
		,head.most_recent_sql_handle
		,0 as [level]
    from 
		cteHead AS head
    where 
		(head.blocking_session_id is null 
		or head.blocking_session_id = 0
		)
		and head.session_id in (select distinct 
									blocking_session_id 
								from 
									cteHead 
								where 
									blocking_session_id != 0
								)
    union all
    select 
		h.head_blocker_session_id
		,blocked.session_id
		,blocked.blocking_session_id
		,blocked.request_status
		,blocked.open_tran_count
		,blocked.wait_type
		,blocked.wait_time
		,blocked.wait_resource
		,h.[sql_handle]
		,h.most_recent_sql_handle
		,[level] + 1
    from 
		cteHead as blocked
		inner join cteBlockingHierarchy as h 
			on (h.session_id = blocked.blocking_session_id 
			and h.session_id != blocked.session_id) --avoid infinite recursion for latch type of blocking
    where 
		h.wait_type collate Latin1_General_BIN not in ('EXCHANGE'
														,'CXPACKET'
													) 
		or h.wait_type is null
)
select 
	bh.*
	,txt.[text] as blocker_query_or_most_recent_query 
from 
	cteBlockingHierarchy as bh 
	outer apply sys.dm_exec_sql_text (isnull([sql_handle], most_recent_sql_handle)) as txt;