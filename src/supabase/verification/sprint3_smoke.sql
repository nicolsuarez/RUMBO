-- Ejecutar SOLO en una instancia local/de pruebas con todas las migraciones.
-- Como postgres, en una sesión completa. Datos ficticios; ROLLBACK al final.
-- No ejecutar en el proyecto compartido. No es un test pgTAP.
begin;
insert into auth.users(id,email,raw_user_meta_data) values
('93000000-0000-4000-8000-000000000001','s3owner@example.test','{"nombre":"Owner Test","username":"s3_test_owner","telefono":"3001234567","fecha_nacimiento":"1990-01-01","intereses":["Senderismo"]}'),
('93000000-0000-4000-8000-000000000002','s3member@example.test','{"nombre":"Member Test","username":"s3_test_member","telefono":"3001234567","fecha_nacimiento":"1990-01-01","intereses":["Senderismo"]}'),
('93000000-0000-4000-8000-000000000003','s3pending@example.test','{"nombre":"Pending Test","username":"s3_test_pending","telefono":"3001234567","fecha_nacimiento":"1990-01-01","intereses":["Senderismo"]}'),
('93000000-0000-4000-8000-000000000004','s3outsider@example.test','{"nombre":"Outsider Test","username":"s3_test_outside","telefono":"3001234567","fecha_nacimiento":"1990-01-01","intereses":["Senderismo"]}');
update public.usuario set rol='organizador' where id_usuario='93000000-0000-4000-8000-000000000001';
insert into public.plan(id_plan,id_organizador,titulo,descripcion,lugar,fecha_inicio,id_tipo_actividad,modalidad,cupos_minimos,cupos_maximos,presupuesto,distancia_km,estado)
select x.id,'93000000-0000-4000-8000-000000000001','Test Sprint 3','Test','Test',now()+interval '1 day',
 (select id_tipo_actividad from public.tipo_actividad where nombre='Senderismo'),'privado',1,10,0,10,'publicado'
from (values ('93100000-0000-4000-8000-000000000001'::uuid),('93100000-0000-4000-8000-000000000002'::uuid)) x(id);
insert into public.inscripcion(id_usuario,id_plan,estado) values
('93000000-0000-4000-8000-000000000002','93100000-0000-4000-8000-000000000001','confirmada'),
('93000000-0000-4000-8000-000000000002','93100000-0000-4000-8000-000000000002','confirmada'),
('93000000-0000-4000-8000-000000000003','93100000-0000-4000-8000-000000000001','pendiente');
set local role authenticated;
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"93000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
do $$
declare r public.recorrido; a public.alerta_sos; blocked boolean;
begin
  r := public.iniciar_recorrido('93100000-0000-4000-8000-000000000001');
  perform set_config('rumbo.test.route',r.id_recorrido::text,true);
  if r.estado <> 'activo' or r.porcentaje_avance <> 0 then raise exception 'FAIL inicio'; end if;
  blocked := false;
  begin perform public.iniciar_recorrido('93100000-0000-4000-8000-000000000002');
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL recorrido simultáneo'; end if;
  r := public.actualizar_recorrido(r.id_recorrido,'avanzar',40);
  if r.porcentaje_avance <> 40 or r.distancia_recorrida <> 4 then raise exception 'FAIL avance'; end if;
  r := public.actualizar_recorrido(r.id_recorrido,'pausar');
  blocked := false;
  begin perform public.actualizar_recorrido(r.id_recorrido,'avanzar',50);
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL avance pausado'; end if;
  a := public.registrar_alerta_sos(r.id_recorrido,'desvio',true);
  if a.tipo <> 'desvio' or a.estado <> 'simulada' or a.latitud is not null then raise exception 'FAIL alerta'; end if;
  blocked := false;
  begin perform public.registrar_alerta_sos(r.id_recorrido,'manual',false);
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL alerta sin confirmación'; end if;
  r := public.actualizar_recorrido(r.id_recorrido,'reanudar');
  if r.estado <> 'activo' or r.porcentaje_avance <> 40 then raise exception 'FAIL reanudar'; end if;
  blocked := false;
  begin update public.recorrido set porcentaje_avance=99 where id_recorrido=r.id_recorrido;
  exception when insufficient_privilege then blocked := true; end;
  if not blocked then raise exception 'FAIL permiso UPDATE directo'; end if;
  insert into public.mensaje(id_plan,contenido) values(r.id_plan,'Mensaje prueba');
  if not exists(select 1 from public.consultar_mensajes_plan(r.id_plan) where nombre_remitente='Member Test') then raise exception 'FAIL lectura chat'; end if;
  blocked := false;
  begin insert into public.mensaje(id_plan,id_usuario,contenido) values(r.id_plan,'93000000-0000-4000-8000-000000000001','Suplantación');
  exception when insufficient_privilege then blocked := true; end;
  if not blocked then raise exception 'FAIL suplantación'; end if;
  insert into public.contacto_emergencia(nombre,telefono) values('Contacto prueba','3001234567');
  update public.contacto_emergencia set parentesco='Amigo' where nombre='Contacto prueba';
  if not exists(select 1 from public.contacto_emergencia where parentesco='Amigo') then raise exception 'FAIL contacto'; end if;
end $$;
-- Pendiente: no puede consultar chat ni iniciar recorrido.
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000003',true);
select set_config('request.jwt.claims','{"sub":"93000000-0000-4000-8000-000000000003","role":"authenticated"}',true);
do $$
declare blocked boolean := false;
begin
  if exists(select 1 from public.mensaje where id_plan='93100000-0000-4000-8000-000000000001') then raise exception 'FAIL lectura pendiente'; end if;
  begin perform public.iniciar_recorrido('93100000-0000-4000-8000-000000000001');
  exception when raise_exception then blocked:=true; end;
  if not blocked then raise exception 'FAIL inicio pendiente'; end if;
end $$;
-- Ajeno: RLS y RPC deben bloquear datos de otros.
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000004',true);
select set_config('request.jwt.claims','{"sub":"93000000-0000-4000-8000-000000000004","role":"authenticated"}',true);
do $$
declare blocked boolean;
begin
  if exists(select 1 from public.recorrido) or exists(select 1 from public.alerta_sos) or exists(select 1 from public.contacto_emergencia) or exists(select 1 from public.mensaje) then raise exception 'FAIL RLS ajeno'; end if;
  blocked := false;
  begin perform public.registrar_alerta_sos(current_setting('rumbo.test.route')::uuid,'manual',true);
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL SOS ajeno'; end if;
  blocked := false;
  begin perform public.actualizar_recorrido(current_setting('rumbo.test.route')::uuid,'finalizar');
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL cambio recorrido ajeno'; end if;
  blocked := false;
  begin insert into public.mensaje(id_plan,contenido) values('93100000-0000-4000-8000-000000000001','No autorizado');
  exception when insufficient_privilege then blocked:=true; end;
  if not blocked then raise exception 'FAIL escritura chat ajeno'; end if;
end $$;
-- Organizador propietario: chat sí, recorrido sin inscripción no.
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"93000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
do $$
declare blocked boolean := false;
begin
  if not exists(select 1 from public.consultar_mensajes_plan('93100000-0000-4000-8000-000000000001')) then raise exception 'FAIL chat organizador'; end if;
  begin perform public.iniciar_recorrido('93100000-0000-4000-8000-000000000001');
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL inicio organizador'; end if;
end $$;
-- Titular: cancelación bloquea reanudación y avance, permite finalizar.
select set_config('request.jwt.claim.sub','93000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"93000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
do $$
declare r public.recorrido; blocked boolean;
begin
  r := public.actualizar_recorrido(current_setting('rumbo.test.route')::uuid,'pausar');
  perform public.cancelar_inscripcion(r.id_plan);
  blocked := false;
  begin perform public.actualizar_recorrido(r.id_recorrido,'reanudar');
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL reanudación cancelada'; end if;
  if exists(select 1 from public.mensaje where id_plan=r.id_plan) then raise exception 'FAIL chat después de cancelar'; end if;
  r := public.actualizar_recorrido(r.id_recorrido,'finalizar');
  if r.estado <> 'finalizado' or r.fin is null or r.porcentaje_avance <> 40 then raise exception 'FAIL finalizar'; end if;
  blocked := false;
  begin perform public.registrar_alerta_sos(r.id_recorrido,'manual',true);
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL SOS finalizado'; end if;
  blocked := false;
  begin perform public.actualizar_recorrido(r.id_recorrido,'reanudar');
  exception when raise_exception then blocked := true; end;
  if not blocked then raise exception 'FAIL reabrir finalizado'; end if;
  r := public.iniciar_recorrido('93100000-0000-4000-8000-000000000002');
  if r.estado <> 'activo' then raise exception 'FAIL inicio nuevo plan'; end if;
  delete from public.contacto_emergencia where nombre='Contacto prueba';
  if exists(select 1 from public.contacto_emergencia) then raise exception 'FAIL eliminar contacto'; end if;
end $$;
reset role;
select 'OK: pruebas funcionales y de permisos completadas' as resultado;
rollback;
