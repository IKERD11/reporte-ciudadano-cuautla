export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string
          id: string
          metadata: Json
          municipality_id: string
          new_values: Json
          old_values: Json
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type: string
          id?: string
          metadata?: Json
          municipality_id: string
          new_values?: Json
          old_values?: Json
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string
          id?: string
          metadata?: Json
          municipality_id?: string
          new_values?: Json
          old_values?: Json
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "audit_logs_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          created_at: string
          default_priority_id: string
          description: string | null
          dynamic_form_schema: Json
          icon: string | null
          id: string
          is_active: boolean
          is_public: boolean
          municipality_id: string
          name: string
          requires_location: boolean
          requires_photo: boolean
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_priority_id: string
          description?: string | null
          dynamic_form_schema?: Json
          icon?: string | null
          id?: string
          is_active?: boolean
          is_public?: boolean
          municipality_id: string
          name: string
          requires_location?: boolean
          requires_photo?: boolean
          sort_order?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_priority_id?: string
          description?: string | null
          dynamic_form_schema?: Json
          icon?: string | null
          id?: string
          is_active?: boolean
          is_public?: boolean
          municipality_id?: string
          name?: string
          requires_location?: boolean
          requires_photo?: boolean
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "categories_default_priority_id_municipality_id_fkey"
            columns: ["default_priority_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "priorities"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "categories_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      consents: {
        Row: {
          accepted_at: string
          consent_type: string
          id: string
          municipality_id: string
          privacy_notice_version: string
          user_id: string
        }
        Insert: {
          accepted_at?: string
          consent_type: string
          id?: string
          municipality_id: string
          privacy_notice_version: string
          user_id: string
        }
        Update: {
          accepted_at?: string
          consent_type?: string
          id?: string
          municipality_id?: string
          privacy_notice_version?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consents_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consents_user_id_municipality_id_fkey"
            columns: ["user_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      departments: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          municipality_id: string
          name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          municipality_id: string
          name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          municipality_id?: string
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "departments_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      identity_verifications: {
        Row: {
          consent_id: string | null
          created_at: string
          document_delete_after: string | null
          document_type: string
          documents_deleted_at: string | null
          expires_at: string | null
          id: string
          is_synthetic: boolean
          municipality_id: string
          provider: string | null
          provider_reference: string | null
          rejected_at: string | null
          request_key: string | null
          status: Database["public"]["Enums"]["identity_status"]
          updated_at: string
          user_id: string
          verification_metadata: Json
          verified_at: string | null
        }
        Insert: {
          consent_id?: string | null
          created_at?: string
          document_delete_after?: string | null
          document_type?: string
          documents_deleted_at?: string | null
          expires_at?: string | null
          id?: string
          is_synthetic?: boolean
          municipality_id: string
          provider?: string | null
          provider_reference?: string | null
          rejected_at?: string | null
          request_key?: string | null
          status?: Database["public"]["Enums"]["identity_status"]
          updated_at?: string
          user_id: string
          verification_metadata?: Json
          verified_at?: string | null
        }
        Update: {
          consent_id?: string | null
          created_at?: string
          document_delete_after?: string | null
          document_type?: string
          documents_deleted_at?: string | null
          expires_at?: string | null
          id?: string
          is_synthetic?: boolean
          municipality_id?: string
          provider?: string | null
          provider_reference?: string | null
          rejected_at?: string | null
          request_key?: string | null
          status?: Database["public"]["Enums"]["identity_status"]
          updated_at?: string
          user_id?: string
          verification_metadata?: Json
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "identity_verifications_consent_id_fkey"
            columns: ["consent_id"]
            isOneToOne: false
            referencedRelation: "consents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "identity_verifications_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "identity_verifications_user_id_municipality_id_fkey"
            columns: ["user_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      municipalities: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          logo_url: string | null
          name: string
          state: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          logo_url?: string | null
          name: string
          state: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          logo_url?: string | null
          name?: string
          state?: string
          updated_at?: string
        }
        Relationships: []
      }
      notifications: {
        Row: {
          body: string
          created_at: string
          id: string
          municipality_id: string
          read_at: string | null
          report_id: string | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          municipality_id: string
          read_at?: string | null
          report_id?: string | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          municipality_id?: string
          read_at?: string | null
          report_id?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_report_id_municipality_id_fkey"
            columns: ["report_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "notifications_user_id_municipality_id_fkey"
            columns: ["user_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      permissions: {
        Row: {
          code: string
          description: string
          id: string
        }
        Insert: {
          code: string
          description: string
          id?: string
        }
        Update: {
          code?: string
          description?: string
          id?: string
        }
        Relationships: []
      }
      priorities: {
        Row: {
          id: string
          is_active: boolean
          municipality_id: string
          name: string
          rank: number
        }
        Insert: {
          id?: string
          is_active?: boolean
          municipality_id: string
          name: string
          rank: number
        }
        Update: {
          id?: string
          is_active?: boolean
          municipality_id?: string
          name?: string
          rank?: number
        }
        Relationships: [
          {
            foreignKeyName: "priorities_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          deleted_at: string | null
          first_name: string
          id: string
          identity_status: Database["public"]["Enums"]["identity_status"]
          is_active: boolean
          last_name: string
          municipality_id: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          first_name?: string
          id: string
          identity_status?: Database["public"]["Enums"]["identity_status"]
          is_active?: boolean
          last_name?: string
          municipality_id: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          first_name?: string
          id?: string
          identity_status?: Database["public"]["Enums"]["identity_status"]
          is_active?: boolean
          last_name?: string
          municipality_id?: string
          phone?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      report_assignments: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          assigned_to: string | null
          department_id: string
          id: string
          municipality_id: string
          report_id: string
          unassigned_at: string | null
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          assigned_to?: string | null
          department_id: string
          id?: string
          municipality_id: string
          report_id: string
          unassigned_at?: string | null
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          assigned_to?: string | null
          department_id?: string
          id?: string
          municipality_id?: string
          report_id?: string
          unassigned_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "report_assignments_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_assignments_assigned_to_municipality_id_fkey"
            columns: ["assigned_to", "municipality_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "report_assignments_department_id_municipality_id_fkey"
            columns: ["department_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "report_assignments_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_assignments_report_id_municipality_id_fkey"
            columns: ["report_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      report_comments: {
        Row: {
          author_id: string | null
          body: string
          created_at: string
          id: string
          is_internal: boolean
          municipality_id: string
          report_id: string
        }
        Insert: {
          author_id?: string | null
          body: string
          created_at?: string
          id?: string
          is_internal?: boolean
          municipality_id: string
          report_id: string
        }
        Update: {
          author_id?: string | null
          body?: string
          created_at?: string
          id?: string
          is_internal?: boolean
          municipality_id?: string
          report_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "report_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_comments_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_comments_report_id_municipality_id_fkey"
            columns: ["report_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      report_images: {
        Row: {
          created_at: string
          id: string
          mime_type: string
          municipality_id: string
          report_id: string
          size: number
          storage_path: string
        }
        Insert: {
          created_at?: string
          id?: string
          mime_type: string
          municipality_id: string
          report_id: string
          size: number
          storage_path: string
        }
        Update: {
          created_at?: string
          id?: string
          mime_type?: string
          municipality_id?: string
          report_id?: string
          size?: number
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "report_images_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_images_report_id_municipality_id_fkey"
            columns: ["report_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      report_status_history: {
        Row: {
          changed_by: string | null
          comment: string | null
          created_at: string
          id: string
          municipality_id: string
          new_status_id: string
          previous_status_id: string | null
          report_id: string
        }
        Insert: {
          changed_by?: string | null
          comment?: string | null
          created_at?: string
          id?: string
          municipality_id: string
          new_status_id: string
          previous_status_id?: string | null
          report_id: string
        }
        Update: {
          changed_by?: string | null
          comment?: string | null
          created_at?: string
          id?: string
          municipality_id?: string
          new_status_id?: string
          previous_status_id?: string | null
          report_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "report_status_history_changed_by_fkey"
            columns: ["changed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_status_history_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_status_history_new_status_id_fkey"
            columns: ["new_status_id"]
            isOneToOne: false
            referencedRelation: "report_statuses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_status_history_previous_status_id_fkey"
            columns: ["previous_status_id"]
            isOneToOne: false
            referencedRelation: "report_statuses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "report_status_history_report_id_municipality_id_fkey"
            columns: ["report_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "reports"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      report_statuses: {
        Row: {
          code: string
          id: string
          is_terminal: boolean
          name: string
        }
        Insert: {
          code: string
          id?: string
          is_terminal?: boolean
          name: string
        }
        Update: {
          code?: string
          id?: string
          is_terminal?: boolean
          name?: string
        }
        Relationships: []
      }
      reports: {
        Row: {
          additional_data: Json
          approximate_address: string | null
          captured_at: string | null
          category_id: string
          citizen_id: string
          closed_at: string | null
          created_at: string
          description: string
          folio: string
          form_schema_snapshot: Json
          gps_accuracy: number | null
          id: string
          idempotency_key: string
          is_pilot: boolean
          location: unknown
          municipality_id: string
          priority_id: string
          resolved_at: string | null
          status_id: string
          subcategory_id: string | null
          updated_at: string
          zone_id: string | null
        }
        Insert: {
          additional_data?: Json
          approximate_address?: string | null
          captured_at?: string | null
          category_id: string
          citizen_id: string
          closed_at?: string | null
          created_at?: string
          description: string
          folio: string
          form_schema_snapshot?: Json
          gps_accuracy?: number | null
          id?: string
          idempotency_key: string
          is_pilot?: boolean
          location?: unknown
          municipality_id: string
          priority_id: string
          resolved_at?: string | null
          status_id: string
          subcategory_id?: string | null
          updated_at?: string
          zone_id?: string | null
        }
        Update: {
          additional_data?: Json
          approximate_address?: string | null
          captured_at?: string | null
          category_id?: string
          citizen_id?: string
          closed_at?: string | null
          created_at?: string
          description?: string
          folio?: string
          form_schema_snapshot?: Json
          gps_accuracy?: number | null
          id?: string
          idempotency_key?: string
          is_pilot?: boolean
          location?: unknown
          municipality_id?: string
          priority_id?: string
          resolved_at?: string | null
          status_id?: string
          subcategory_id?: string | null
          updated_at?: string
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reports_category_id_municipality_id_fkey"
            columns: ["category_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "reports_citizen_id_municipality_id_fkey"
            columns: ["citizen_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "reports_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_priority_id_municipality_id_fkey"
            columns: ["priority_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "priorities"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "reports_status_id_fkey"
            columns: ["status_id"]
            isOneToOne: false
            referencedRelation: "report_statuses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_subcategory_id_category_id_municipality_id_fkey"
            columns: ["subcategory_id", "category_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "subcategories"
            referencedColumns: ["id", "category_id", "municipality_id"]
          },
          {
            foreignKeyName: "reports_zone_id_municipality_id_fkey"
            columns: ["zone_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      role_permissions: {
        Row: {
          permission_id: string
          role_id: string
        }
        Insert: {
          permission_id: string
          role_id: string
        }
        Update: {
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          code: string
          description: string
          id: string
        }
        Insert: {
          code: string
          description: string
          id?: string
        }
        Update: {
          code?: string
          description?: string
          id?: string
        }
        Relationships: []
      }
      settings: {
        Row: {
          citizen_registration_enabled: boolean
          emergency_contact: string | null
          evidence_retention_days: number | null
          identity_retention_days: number | null
          max_report_images: number
          municipality_id: string
          pilot_reports_enabled: boolean
          privacy_notice_url: string | null
          privacy_notice_version: string | null
          updated_at: string
        }
        Insert: {
          citizen_registration_enabled?: boolean
          emergency_contact?: string | null
          evidence_retention_days?: number | null
          identity_retention_days?: number | null
          max_report_images?: number
          municipality_id: string
          pilot_reports_enabled?: boolean
          privacy_notice_url?: string | null
          privacy_notice_version?: string | null
          updated_at?: string
        }
        Update: {
          citizen_registration_enabled?: boolean
          emergency_contact?: string | null
          evidence_retention_days?: number | null
          identity_retention_days?: number | null
          max_report_images?: number
          municipality_id?: string
          pilot_reports_enabled?: boolean
          privacy_notice_url?: string | null
          privacy_notice_version?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "settings_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: true
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      sla_rules: {
        Row: {
          category_id: string | null
          id: string
          is_active: boolean
          municipality_id: string
          priority_id: string
          resolution_minutes: number
          response_minutes: number
        }
        Insert: {
          category_id?: string | null
          id?: string
          is_active?: boolean
          municipality_id: string
          priority_id: string
          resolution_minutes: number
          response_minutes: number
        }
        Update: {
          category_id?: string | null
          id?: string
          is_active?: boolean
          municipality_id?: string
          priority_id?: string
          resolution_minutes?: number
          response_minutes?: number
        }
        Relationships: [
          {
            foreignKeyName: "sla_rules_category_id_municipality_id_fkey"
            columns: ["category_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "sla_rules_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sla_rules_priority_id_municipality_id_fkey"
            columns: ["priority_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "priorities"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      subcategories: {
        Row: {
          category_id: string
          id: string
          is_active: boolean
          municipality_id: string
          name: string
          sort_order: number
        }
        Insert: {
          category_id: string
          id?: string
          is_active?: boolean
          municipality_id: string
          name: string
          sort_order?: number
        }
        Update: {
          category_id?: string
          id?: string
          is_active?: boolean
          municipality_id?: string
          name?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "subcategories_category_id_municipality_id_fkey"
            columns: ["category_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id", "municipality_id"]
          },
          {
            foreignKeyName: "subcategories_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          municipality_id: string | null
          role_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          municipality_id?: string | null
          role_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          municipality_id?: string | null
          role_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_user_id_municipality_id_fkey"
            columns: ["user_id", "municipality_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id", "municipality_id"]
          },
        ]
      }
      zones: {
        Row: {
          boundary: unknown
          id: string
          municipality_id: string
          name: string
        }
        Insert: {
          boundary: unknown
          id?: string
          municipality_id: string
          name: string
        }
        Update: {
          boundary?: unknown
          id?: string
          municipality_id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "zones_municipality_id_fkey"
            columns: ["municipality_id"]
            isOneToOne: false
            referencedRelation: "municipalities"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      complete_citizen_profile: {
        Args: {
          p_first_name: string
          p_last_name: string
          p_municipality_id: string
        }
        Returns: {
          created_at: string
          deleted_at: string | null
          first_name: string
          id: string
          identity_status: Database["public"]["Enums"]["identity_status"]
          is_active: boolean
          last_name: string
          municipality_id: string
          phone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      identity_pilot_service: {
        Args: {
          p_action: string
          p_actor: string
          p_case?: string
          p_key?: string
          p_session: string
          p_side?: string
          p_version?: string
        }
        Returns: Json
      }
      identity_purge_authorized: {
        Args: { p_case?: string; p_token: string }
        Returns: Json
      }
      identity_purge_service: { Args: { p_case?: string }; Returns: Json }
      list_registration_municipalities: {
        Args: never
        Returns: {
          id: string
          name: string
          state: string
        }[]
      }
      report_pilot_service: {
        Args: {
          p_action: string
          p_actor: string
          p_filter?: string
          p_key?: string
          p_offset?: number
          p_payload?: Json
          p_report?: string
          p_session: string
        }
        Returns: Json
      }
      report_upload_purge: {
        Args: { p_case?: string; p_token: string }
        Returns: Json
      }
      update_my_profile: {
        Args: { p_first_name: string; p_last_name: string; p_phone?: string }
        Returns: {
          created_at: string
          deleted_at: string | null
          first_name: string
          id: string
          identity_status: Database["public"]["Enums"]["identity_status"]
          is_active: boolean
          last_name: string
          municipality_id: string
          phone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      identity_status:
        | "PENDING"
        | "DOCUMENT_CAPTURED"
        | "PROCESSING"
        | "UNDER_REVIEW"
        | "VERIFIED"
        | "REJECTED"
        | "EXPIRED"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      identity_status: [
        "PENDING",
        "DOCUMENT_CAPTURED",
        "PROCESSING",
        "UNDER_REVIEW",
        "VERIFIED",
        "REJECTED",
        "EXPIRED",
      ],
    },
  },
} as const
