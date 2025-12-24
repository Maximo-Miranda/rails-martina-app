# frozen_string_literal: true

module RansackPagyIndex
  extend ActiveSupport::Concern

  PAGINATION_KEYS = %i[count page limit pages previous next from to].freeze

  private

  def pagy_limit(default: 10, max: 100)
    limit = params[:limit].to_i
    limit = default if limit <= 0
    [ limit, max ].min
  end

  def pagy_pagination(pagy)
    pagy.data_hash(data_keys: PAGINATION_KEYS)
  end

  # Builds a Ransack object and returns [q, filters_hash].
  # - Enforces single-sort (q[s]) even if an array is provided.
  # - Allows only a small set of q keys (allowed_q_keys) and sort fields (allowed_sort_fields).
  def build_ransack(scope, allowed_q_keys:, allowed_sort_fields:, default_sort: "created_at desc")
    raw_q = params[:q]
    raw_q = {} if raw_q.blank?
    raw_q = ActionController::Parameters.new(raw_q) unless raw_q.is_a?(ActionController::Parameters)

    permitted = raw_q.permit(*allowed_q_keys, :s, s: [])

    sort = extract_single_sort(permitted)
    sort = sanitize_sort(sort, allowed_sort_fields)

    filters = permitted.to_h
    filters["s"] = sort if sort.present?

    q = scope.ransack(filters)
    q.sorts = default_sort if q.sorts.empty?

    [ q, filters ]
  end

  def extract_single_sort(permitted_q)
    sort = permitted_q[:s]
    sort = sort.first if sort.is_a?(Array)
    sort.presence
  end

  def sanitize_sort(sort, allowed_fields)
    return nil if sort.blank?

    field, direction = sort.to_s.split
    return nil if field.blank? || direction.blank?

    direction = direction.downcase
    return nil unless %w[asc desc].include?(direction)

    return nil unless allowed_fields.include?(field)

    "#{field} #{direction}"
  end
end
